from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from PySide6.QtCore import (
    Property,
    QObject,
    QThread,
    Signal,
    Slot,
)

# ============================================================
# Paths
# ============================================================

BASE_DIR = Path(__file__).resolve().parent
RULES_DIR = BASE_DIR / "rules"


# ============================================================
# Limits
# ============================================================

MAX_FILE_SIZE = 256 * 1024
MAX_FILE_CHARS = 32_768


# ============================================================
# Data model
# ============================================================


@dataclass
class ProjectFile:
    path: str
    content: str


# ============================================================
# Processing Worker
# ============================================================


class ProcessingWorker(QObject):
    finished = Signal(str, object, str)
    error = Signal(str)
    cancelled = Signal()

    def __init__(
        self,
        root: Path,
        exclude_dirs: set[str],
        exclude_files: set[str],
        content_extensions: set[str],
        content_files: set[str],
    ) -> None:

        super().__init__()

        self.root = root

        self.exclude_dirs = set(exclude_dirs)
        self.exclude_files = set(exclude_files)
        self.content_extensions = set(content_extensions)
        self.content_files = set(content_files)

        self._cancel_requested = False

    # ========================================================
    # Cancel
    # ========================================================

    @Slot()
    def cancel(self) -> None:
        self._cancel_requested = True

    def is_cancelled(self) -> bool:
        return self._cancel_requested

    # ========================================================
    # Rules
    # ========================================================

    def is_excluded_dir(
        self,
        path: Path,
    ) -> bool:

        return path.name in self.exclude_dirs

    def is_excluded_file(
        self,
        path: Path,
    ) -> bool:

        return path.name in self.exclude_files

    def is_content_file(
        self,
        path: Path,
    ) -> bool:

        return (
            path.suffix.lower() in self.content_extensions
            or path.name in self.content_files
        )

    # ========================================================
    # Safe read
    # ========================================================

    def safe_read_file(
        self,
        path: Path,
    ) -> str:

        if self.is_cancelled():
            return ""

        try:
            if path.stat().st_size > MAX_FILE_SIZE:
                return "[SKIPPED: FILE TOO LARGE]"

            content = path.read_text(
                encoding="utf-8",
                errors="ignore",
            )

            if len(content) > MAX_FILE_CHARS:
                content = content[:MAX_FILE_CHARS] + "\n...[TRUNCATED]"

            return content

        except Exception as exc:
            return f"[UNREADABLE FILE: {exc}]"

    # ========================================================
    # Build tree
    # ========================================================

    def build_tree(self) -> str:

        lines: list[str] = []

        lines.append(self.root.name)

        def walk(
            directory: Path,
            prefix: str,
        ) -> None:

            if self.is_cancelled():
                return

            try:
                entries = list(directory.iterdir())

            except (
                OSError,
                PermissionError,
            ):
                return

            filtered: list[Path] = []

            for entry in entries:
                if self.is_cancelled():
                    return

                if entry.is_dir():
                    if self.is_excluded_dir(entry):
                        continue

                elif entry.is_file():
                    if self.is_excluded_file(entry):
                        continue

                filtered.append(entry)

            filtered.sort(
                key=lambda item: (
                    item.is_file(),
                    item.name.lower(),
                )
            )

            for index, entry in enumerate(filtered):
                if self.is_cancelled():
                    return

                is_last = index == len(filtered) - 1

                connector = "└── " if is_last else "├── "

                lines.append(prefix + connector + entry.name)

                if entry.is_dir():
                    next_prefix = prefix + ("    " if is_last else "│   ")

                    walk(
                        entry,
                        next_prefix,
                    )

        walk(
            self.root,
            "",
        )

        return "\n".join(lines)

    # ========================================================
    # Collect content files
    # ========================================================

    def collect_files(
        self,
    ) -> list[ProjectFile]:

        result: list[ProjectFile] = []

        for dirpath, dirnames, filenames in os.walk(self.root):
            if self.is_cancelled():
                return result

            current_dir = Path(dirpath)

            dirnames[:] = [
                dirname
                for dirname in dirnames
                if not self.is_excluded_dir(current_dir / dirname)
            ]

            for filename in filenames:
                if self.is_cancelled():
                    return result

                path = current_dir / filename

                if self.is_excluded_file(path):
                    continue

                if not self.is_content_file(path):
                    continue

                try:
                    relative_path = path.relative_to(self.root)

                except ValueError:
                    continue

                content = self.safe_read_file(path)

                result.append(
                    ProjectFile(
                        path=str(relative_path),
                        content=content,
                    )
                )

        result.sort(key=lambda item: item.path.lower())

        return result

    # ========================================================
    # Run
    # ========================================================

    @Slot()
    def run(self) -> None:

        try:
            if self.is_cancelled():
                self.cancelled.emit()
                return

            tree = self.build_tree()

            if self.is_cancelled():
                self.cancelled.emit()
                return

            files = self.collect_files()

            if self.is_cancelled():
                self.cancelled.emit()
                return

            statistics = (
                f"Project: {self.root.name}\n"
                f"Path: {self.root}\n"
                f"Content files: {len(files)}\n"
                f"Excluded directories: "
                f"{len(self.exclude_dirs)}\n"
                f"Excluded files: "
                f"{len(self.exclude_files)}\n"
                f"Content extensions: "
                f"{len(self.content_extensions)}\n"
                f"Content file names: "
                f"{len(self.content_files)}"
            )

            self.finished.emit(
                tree,
                files,
                statistics,
            )

        except Exception as exc:
            self.error.emit(f"{type(exc).__name__}: {exc}")


# ============================================================
# Backend
# ============================================================


class ProjectBackend(QObject):
    projectPathChanged = Signal()

    treeChanged = Signal()
    filesChanged = Signal()
    statisticsChanged = Signal()

    processingChanged = Signal()

    rulesChanged = Signal()

    presetNamesChanged = Signal()

    currentFileChanged = Signal()

    errorOccurred = Signal(str)

    # ========================================================
    # Constructor
    # ========================================================

    def __init__(
        self,
        parent: QObject | None = None,
    ) -> None:

        super().__init__(parent)

        # ----------------------------------------------------
        # Project
        # ----------------------------------------------------

        self._project_path = ""

        # ----------------------------------------------------
        # Results
        # ----------------------------------------------------

        self._tree = ""

        self._statistics = ""

        self._project_files: list[ProjectFile] = []

        # ----------------------------------------------------
        # Navigation
        # ----------------------------------------------------

        self._current_file_index = -1

        # ----------------------------------------------------
        # Processing
        # ----------------------------------------------------

        self._processing = False

        self._thread: QThread | None = None
        self._worker: ProcessingWorker | None = None

        # ----------------------------------------------------
        # Rules
        # ----------------------------------------------------

        self._exclude_dirs: set[str] = {".git"}

        self._exclude_files: set[str] = set()

        self._content_extensions: set[str] = set()

        self._content_files: set[str] = set()

        # ----------------------------------------------------
        # Presets
        # ----------------------------------------------------

        self._preset_names: list[str] = []

        self._scan_presets()

        self._load_default_preset()

    # ========================================================
    # Project Path
    # ========================================================

    @Property(
        str,
        notify=projectPathChanged,
    )
    def projectPath(self) -> str:

        return self._project_path

    @projectPath.setter
    def projectPath(
        self,
        value: str,
    ) -> None:

        value = str(value).strip()

        if value == self._project_path:
            return

        self._project_path = value

        self.projectPathChanged.emit()

    # ========================================================
    # Tree
    # ========================================================

    @Property(
        str,
        notify=treeChanged,
    )
    def tree(self) -> str:

        return self._tree

    # ========================================================
    # Statistics
    # ========================================================

    @Property(
        str,
        notify=statisticsChanged,
    )
    def statistics(self) -> str:

        return self._statistics

    # ========================================================
    # Processing
    # ========================================================

    @Property(
        bool,
        notify=processingChanged,
    )
    def processing(self) -> bool:

        return self._processing

    # ========================================================
    # Rules
    # ========================================================

    @Property(
        str,
        notify=rulesChanged,
    )
    def excludeDirs(self) -> str:

        return self._format_rules(self._exclude_dirs)

    @Property(
        str,
        notify=rulesChanged,
    )
    def excludeFiles(self) -> str:

        return self._format_rules(self._exclude_files)

    @Property(
        str,
        notify=rulesChanged,
    )
    def contentExtensions(self) -> str:

        return self._format_rules(self._content_extensions)

    @Property(
        str,
        notify=rulesChanged,
    )
    def contentFiles(self) -> str:

        return self._format_rules(self._content_files)

    # ========================================================
    # Presets
    # ========================================================

    @Property(
        "QStringList",
        notify=presetNamesChanged,
    )
    def presetNames(self) -> list[str]:

        return self._preset_names

    # ========================================================
    # Files
    # ========================================================

    @Property(
        int,
        notify=currentFileChanged,
    )
    def currentFileIndex(self) -> int:

        return self._current_file_index

    @Property(
        int,
        notify=currentFileChanged,
    )
    def fileCount(self) -> int:

        return len(self._project_files)

    @Property(
        str,
        notify=currentFileChanged,
    )
    def currentFilePath(self) -> str:

        if not (0 <= self._current_file_index < len(self._project_files)):
            return ""

        return self._project_files[self._current_file_index].path

    # ========================================================
    # Complete Contents
    # ========================================================

    @Property(
        str,
        notify=filesChanged,
    )
    def allContents(self) -> str:

        if not self._project_files:
            return ""

        parts: list[str] = []

        for file in self._project_files:
            parts.append("============================================================")

            parts.append(f"--- FILE: {file.path} ---")

            parts.append("============================================================")

            parts.append(file.content)

            parts.append("")

        return "\n".join(parts)

    # ========================================================
    # Current file position
    # ========================================================

    @Property(
        int,
        notify=currentFileChanged,
    )
    def currentFilePosition(self) -> int:

        if not (0 <= self._current_file_index < len(self._project_files)):
            return -1

        position = 0

        for index, file in enumerate(self._project_files):
            if index == self._current_file_index:
                return position

            position += len(
                "============================================================\n"
            )

            position += len(f"--- FILE: {file.path} ---\n")

            position += len(
                "============================================================\n"
            )

            position += len(file.content)

            position += 2

        return -1

    # ========================================================
    # Navigation state
    # ========================================================

    @Property(
        bool,
        notify=currentFileChanged,
    )
    def canPrevious(self) -> bool:

        return self._current_file_index > 0

    @Property(
        bool,
        notify=currentFileChanged,
    )
    def canNext(self) -> bool:

        return (
            self._current_file_index >= 0
            and self._current_file_index < len(self._project_files) - 1
        )

    # ========================================================
    # Preset scanning
    # ========================================================

    def _scan_presets(self) -> None:

        self._preset_names = []

        if not RULES_DIR.exists():
            return

        for path in RULES_DIR.glob("*.json"):
            try:
                with path.open(
                    "r",
                    encoding="utf-8",
                ) as file:
                    data = json.load(file)

                name = str(
                    data.get(
                        "name",
                        path.stem,
                    )
                ).strip()

                if name:
                    self._preset_names.append(name)

            except Exception:
                continue

        self._preset_names.sort(key=str.lower)

        self.presetNamesChanged.emit()

    # ========================================================
    # Find preset
    # ========================================================

    def _find_preset(
        self,
        name: str,
    ) -> Path | None:

        wanted = name.strip().lower()

        if not RULES_DIR.exists():
            return None

        for path in RULES_DIR.glob("*.json"):
            try:
                with path.open(
                    "r",
                    encoding="utf-8",
                ) as file:
                    data = json.load(file)

                preset_name = (
                    str(
                        data.get(
                            "name",
                            path.stem,
                        )
                    )
                    .strip()
                    .lower()
                )

                if preset_name == wanted:
                    return path

            except Exception:
                continue

        return None

    # ========================================================
    # Default preset
    # ========================================================

    def _load_default_preset(self) -> None:

        path = self._find_preset("Default")

        if path is not None:
            self._merge_preset(path)

        self.rulesChanged.emit()

    # ========================================================
    # Add preset
    # ========================================================

    @Slot(str)
    def addPreset(
        self,
        name: str,
    ) -> None:

        path = self._find_preset(name)

        if path is None:
            self.errorOccurred.emit(f"Preset not found: {name}")

            return

        if self._merge_preset(path):
            self.rulesChanged.emit()

    # ========================================================
    # Merge preset
    # ========================================================

    def _merge_preset(
        self,
        path: Path,
    ) -> bool:

        try:
            with path.open(
                "r",
                encoding="utf-8",
            ) as file:
                data: dict[str, Any] = json.load(file)

        except Exception as exc:
            self.errorOccurred.emit(f"Could not read preset:\n{exc}")

            return False

        self._exclude_dirs.update(
            self._read_list(
                data.get(
                    "exclude_dirs",
                    [],
                )
            )
        )

        self._exclude_files.update(
            self._read_list(
                data.get(
                    "exclude_files",
                    [],
                )
            )
        )

        for extension in self._read_list(
            data.get(
                "content_extensions",
                [],
            )
        ):
            extension = extension.lower()

            if not extension.startswith("."):
                extension = "." + extension

            self._content_extensions.add(extension)

        self._content_files.update(
            self._read_list(
                data.get(
                    "content_files",
                    [],
                )
            )
        )

        return True

    # ========================================================
    # Clear
    # ========================================================

    @Slot()
    def clearRules(self) -> None:

        self._exclude_dirs = {".git"}

        self._exclude_files = set()

        self._content_extensions = set()

        self._content_files = set()

        self.rulesChanged.emit()

    # ========================================================
    # Manual rules
    # ========================================================

    @Slot(str)
    def setExcludeDirs(
        self,
        value: str,
    ) -> None:

        self._exclude_dirs = self._parse_rules(value)

        self.rulesChanged.emit()

    @Slot(str)
    def setExcludeFiles(
        self,
        value: str,
    ) -> None:

        self._exclude_files = self._parse_rules(value)

        self.rulesChanged.emit()

    @Slot(str)
    def setContentExtensions(
        self,
        value: str,
    ) -> None:

        result: set[str] = set()

        for item in self._parse_rules(value):
            item = item.lower()

            if not item.startswith("."):
                item = "." + item

            result.add(item)

        self._content_extensions = result

        self.rulesChanged.emit()

    @Slot(str)
    def setContentFiles(
        self,
        value: str,
    ) -> None:

        self._content_files = self._parse_rules(value)

        self.rulesChanged.emit()

    # ========================================================
    # Process
    # ========================================================

    @Slot()
    def process(self) -> None:

        if self._processing:
            return

        if not self._project_path:
            self.errorOccurred.emit("Please select a project folder.")

            return

        root = Path(self._project_path).expanduser().resolve()

        if not root.exists():
            self.errorOccurred.emit(f"Project folder does not exist:\n{root}")

            return

        if not root.is_dir():
            self.errorOccurred.emit(f"Selected path is not a directory:\n{root}")

            return

        # ----------------------------------------------------
        # Reset previous result
        # ----------------------------------------------------

        self._tree = ""
        self._statistics = ""

        self._project_files = []

        self._current_file_index = -1

        self.treeChanged.emit()
        self.statisticsChanged.emit()
        self.filesChanged.emit()
        self.currentFileChanged.emit()

        # ----------------------------------------------------
        # Start worker
        # ----------------------------------------------------

        self._processing = True
        self.processingChanged.emit()

        thread = QThread()

        worker = ProcessingWorker(
            root,
            self._exclude_dirs.copy(),
            self._exclude_files.copy(),
            self._content_extensions.copy(),
            self._content_files.copy(),
        )

        self._thread = thread
        self._worker = worker

        worker.moveToThread(thread)

        thread.started.connect(worker.run)

        worker.finished.connect(self._processing_finished)

        worker.error.connect(self._processing_error)

        worker.cancelled.connect(self._processing_cancelled)

        worker.finished.connect(thread.quit)

        worker.error.connect(thread.quit)

        worker.cancelled.connect(thread.quit)

        thread.finished.connect(worker.deleteLater)

        thread.finished.connect(thread.deleteLater)

        thread.finished.connect(self._thread_finished)

        thread.start()

    # ========================================================
    # Cancel
    # ========================================================

    @Slot()
    def cancel(self) -> None:

        if self._worker is not None:
            self._worker.cancel()

    # ========================================================
    # Processing finished
    # ========================================================

    @Slot(str, object, str)
    def _processing_finished(
        self,
        tree: str,
        files: object,
        statistics: str,
    ) -> None:

        self._tree = tree

        if isinstance(files, list):
            self._project_files = files

        else:
            self._project_files = []

        self._statistics = statistics

        if self._project_files:
            self._current_file_index = 0

        else:
            self._current_file_index = -1

        self.treeChanged.emit()

        self.statisticsChanged.emit()

        self.filesChanged.emit()

        self.currentFileChanged.emit()

    # ========================================================
    # Processing error
    # ========================================================

    @Slot(str)
    def _processing_error(
        self,
        message: str,
    ) -> None:

        self.errorOccurred.emit(message)

    # ========================================================
    # Processing cancelled
    # ========================================================

    @Slot()
    def _processing_cancelled(self) -> None:

        pass

    # ========================================================
    # Thread finished
    # ========================================================

    @Slot()
    def _thread_finished(self) -> None:

        self._worker = None
        self._thread = None

        self._processing = False

        self.processingChanged.emit()

    # ========================================================
    # Navigation
    # ========================================================

    @Slot()
    def previousFile(self) -> None:

        if self.canPrevious:
            self._current_file_index -= 1

            self.currentFileChanged.emit()

    @Slot()
    def nextFile(self) -> None:

        if self.canNext:
            self._current_file_index += 1

            self.currentFileChanged.emit()

    @Slot()
    def firstFile(self) -> None:

        if self._project_files:
            self._current_file_index = 0

            self.currentFileChanged.emit()

    @Slot()
    def lastFile(self) -> None:

        if self._project_files:
            self._current_file_index = len(self._project_files) - 1

            self.currentFileChanged.emit()

    # ========================================================
    # Helpers
    # ========================================================

    @staticmethod
    def _read_list(
        value: Any,
    ) -> set[str]:

        if not isinstance(value, list):
            return set()

        return {str(item).strip() for item in value if str(item).strip()}

    @staticmethod
    def _parse_rules(
        value: str,
    ) -> set[str]:

        return {item.strip() for item in value.split(",") if item.strip()}

    @staticmethod
    def _format_rules(
        values: set[str],
    ) -> str:

        return ", ".join(
            sorted(
                values,
                key=str.lower,
            )
        )
