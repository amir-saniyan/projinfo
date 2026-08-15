#!/usr/bin/env python3

import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


def main() -> int:
    app = QGuiApplication(sys.argv)

    app.setApplicationName("ProjInfo")

    engine = QQmlApplicationEngine()

    backend_path = Path(__file__).resolve().parent / "backend.py"

    if not backend_path.exists():
        print(f"ERROR: backend.py not found: {backend_path}")
        return 1

    from backend import ProjectBackend

    backend = ProjectBackend()

    engine.rootContext().setContextProperty(
        "backend",
        backend,
    )

    qml_path = Path(__file__).resolve().parent / "qml" / "Main.qml"

    if not qml_path.exists():
        print(f"ERROR: Main.qml not found: {qml_path}")
        return 1

    engine.load(QUrl.fromLocalFile(str(qml_path)))

    if not engine.rootObjects():
        print("ERROR: Failed to load Main.qml")
        return 1

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
