import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: window

    visible: true

    width: 1200
    height: 820

    minimumWidth: 950
    minimumHeight: 680

    title: "ProjInfo"

    // =========================================================
    // FIXED THEME
    // =========================================================
    //
    // ProjInfo intentionally does NOT follow the operating
    // system light/dark theme.
    //
    // All colors and font sizes are defined here.
    //
    // =========================================================

    QtObject {
        id: theme

        // -----------------------------------------------------
        // Window
        // -----------------------------------------------------

        property color windowBackground: "#f4f6f8"

        // -----------------------------------------------------
        // Cards
        // -----------------------------------------------------

        property color cardBackground: "#ffffff"
        property color cardBorder: "#dfe3e8"

        // -----------------------------------------------------
        // Inputs
        // -----------------------------------------------------

        property color inputBackground: "#fafbfc"
        property color inputBorder: "#d9dde2"

        // -----------------------------------------------------
        // Text
        // -----------------------------------------------------

        property color textPrimary: "#20242a"
        property color textSecondary: "#59616b"
        property color textMuted: "#7a828c"

        // -----------------------------------------------------
        // Accent
        // -----------------------------------------------------

        property color accent: "#4f6fd8"
        property color accentDark: "#3f5fc4"
        property color accentLight: "#eef2ff"

        // -----------------------------------------------------
        // Buttons
        // -----------------------------------------------------

        property color buttonBackground: "#f7f8fa"
        property color buttonHover: "#eef2ff"
        property color buttonPressed: "#e2e8fb"
        property color buttonDisabled: "#f1f2f4"

        property color buttonText: "#20242a"
        property color buttonTextDisabled: "#a0a6ad"

        // -----------------------------------------------------
        // ComboBox
        // -----------------------------------------------------

        property color comboBackground: "#f7f8fa"
        property color comboHover: "#eef2ff"

        property color comboPopupBackground: "#ffffff"
        property color comboPopupHover: "#eef2ff"

        // -----------------------------------------------------
        // Tabs
        // -----------------------------------------------------

        property color tabActiveBackground: "#ffffff"
        property color tabActiveText: "#20242a"
        property color tabInactiveText: "#59616b"

        // -----------------------------------------------------
        // Status
        // -----------------------------------------------------

        property color statusReady: "#4b7a55"
        property color statusProcessing: "#b2762c"
        property color statusError: "#b94a48"
        property color statusNeutral: "#69727d"

        // -----------------------------------------------------
        // Header / Logo
        // -----------------------------------------------------

        property color logoBackground: "#e9eeff"
        property color logoForeground: "#4f6fd8"

        // -----------------------------------------------------
        // Fonts
        // -----------------------------------------------------

        property string uiFont: "Sans"

        property int fontTitle: 28
        property int fontSubtitle: 13

        property int fontSection: 18

        property int fontNormal: 15
        property int fontSmall: 14
        property int fontTiny: 13
        property int fontCode: 14

        // -----------------------------------------------------
        // Sizes
        // -----------------------------------------------------

        property int radius: 10
        property int smallRadius: 7

        property int inputHeight: 38
        property int buttonHeight: 40

        property int headerHeight: 48

        // -----------------------------------------------------
        // Spacing
        // -----------------------------------------------------

        property int pageMargin: 24
        property int sectionSpacing: 14
        property int cardPadding: 16
    }

    color: theme.windowBackground

    // =========================================================
    // Helper Components
    // =========================================================

    // =========================================================
    // Standard Navigation Button
    // =========================================================

    Component {
        id: navigationButton

        Button {

            font.family:
                theme.uiFont

            font.pixelSize:
                theme.fontSmall

            font.bold: false

            background: Rectangle {

                radius:
                    theme.smallRadius

                color:
                    !parent.enabled
                    ? theme.buttonDisabled
                    :
                    parent.pressed
                    ? theme.buttonPressed
                    :
                    parent.hovered
                    ? theme.buttonHover
                    : theme.buttonBackground

                border.color:
                    !parent.enabled
                    ? "#e2e4e7"
                    :
                    parent.hovered
                    ? theme.accent
                    : theme.inputBorder

                border.width: 1
            }

            contentItem: Text {

                text:
                    parent.text

                horizontalAlignment:
                    Text.AlignHCenter

                verticalAlignment:
                    Text.AlignVCenter

                font:
                    parent.font

                color:
                    parent.enabled
                    ? theme.buttonText
                    : theme.buttonTextDisabled
            }
        }
    }

    // =========================================================
    // Folder Dialog
    // =========================================================

    FolderDialog {
        id: folderDialog

        title: "Select Project Folder"

        onAccepted: {

            var path =
                selectedFolder.toString()

            if (path.startsWith("file://")) {
                path = path.substring(7)
            }

            backend.projectPath = path

            statusText.text =
                "Project folder selected"

            statusText.color =
                theme.statusReady
        }
    }

    // =========================================================
    // Error Dialog
    // =========================================================

    MessageDialog {
        id: errorDialog

        title: "ProjInfo"

        buttons:
            MessageDialog.Ok
    }

    // =========================================================
    // Backend Connections
    // =========================================================

    Connections {

        target: backend

        function onErrorOccurred(message) {

            errorDialog.text = message

            errorDialog.open()

            statusText.text =
                "Error"

            statusText.color =
                theme.statusError
        }

        function onProcessingChanged() {

            if (backend.processing) {

                statusText.text =
                    "Processing..."

                statusText.color =
                    theme.statusProcessing

            } else if (
                backend.fileCount > 0
            ) {

                statusText.text =
                    "Ready • "
                    + backend.fileCount
                    + " files"

                statusText.color =
                    theme.statusReady

            } else if (
                backend.projectPath.length > 0
            ) {

                statusText.text =
                    "Ready"

                statusText.color =
                    theme.statusReady
            }
        }

        function onFilesChanged() {

            if (
                backend.processing
            ) {
                return
            }

            if (
                backend.fileCount > 0
            ) {

                statusText.text =
                    "Ready • "
                    + backend.fileCount
                    + " files"

                statusText.color =
                    theme.statusReady

            } else {

                statusText.text =
                    "Ready"

                statusText.color =
                    theme.statusReady
            }
        }
    }

    // =========================================================
    // Main Layout
    // =========================================================

    ColumnLayout {

        anchors.fill: parent

        anchors.leftMargin:
            theme.pageMargin

        anchors.rightMargin:
            theme.pageMargin

        anchors.topMargin: 18

        anchors.bottomMargin: 12

        spacing:
            theme.sectionSpacing

        // =====================================================
        // Header
        // =====================================================

        RowLayout {

            Layout.fillWidth: true

            Layout.preferredHeight:
                theme.headerHeight

            spacing: 12

            // -------------------------------------------------
            // Logo
            // -------------------------------------------------

            Rectangle {

                Layout.preferredWidth: 44
                Layout.preferredHeight: 44

                radius: 11

                color:
                    theme.logoBackground

                Canvas {

                    anchors.fill: parent

                    anchors.margins: 9

                    onPaint: {

                        var ctx =
                            getContext("2d")

                        ctx.clearRect(
                            0,
                            0,
                            width,
                            height
                        )

                        ctx.strokeStyle =
                            theme.logoForeground

                        ctx.lineWidth = 2.3

                        ctx.lineCap = "round"

                        ctx.lineJoin = "round"

                        // Folder

                        ctx.beginPath()

                        ctx.moveTo(
                            width * 0.12,
                            height * 0.30
                        )

                        ctx.lineTo(
                            width * 0.40,
                            height * 0.30
                        )

                        ctx.lineTo(
                            width * 0.50,
                            height * 0.42
                        )

                        ctx.lineTo(
                            width * 0.88,
                            height * 0.42
                        )

                        ctx.lineTo(
                            width * 0.78,
                            height * 0.82
                        )

                        ctx.lineTo(
                            width * 0.15,
                            height * 0.82
                        )

                        ctx.closePath()

                        ctx.stroke()

                        // Detail

                        ctx.beginPath()

                        ctx.moveTo(
                            width * 0.24,
                            height * 0.53
                        )

                        ctx.lineTo(
                            width * 0.68,
                            height * 0.53
                        )

                        ctx.stroke()
                    }
                }
            }

            // -------------------------------------------------
            // Title
            // -------------------------------------------------

            ColumnLayout {

                Layout.fillWidth: true

                spacing: 1

                Label {

                    text:
                        "ProjInfo"

                    font.family:
                        theme.uiFont

                    font.pixelSize:
                        theme.fontTitle

                    font.bold: true

                    color:
                        theme.textPrimary
                }

                Label {

                    text:
                        "Project information viewer"

                    font.family:
                        theme.uiFont

                    font.pixelSize:
                        theme.fontSubtitle

                    color:
                        theme.textMuted
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        // =====================================================
        // Project Path
        // =====================================================

        Rectangle {

            Layout.fillWidth: true

            Layout.preferredHeight: 70

            radius:
                theme.radius

            color:
                theme.cardBackground

            border.color:
                theme.cardBorder

            border.width: 1

            RowLayout {

                anchors.fill: parent

                anchors.leftMargin:
                    theme.cardPadding

                anchors.rightMargin:
                    theme.cardPadding

                spacing: 12

                Label {

                    text:
                        "Project"

                    Layout.preferredWidth: 70

                    font.family:
                        theme.uiFont

                    font.pixelSize:
                        theme.fontNormal

                    font.bold: true

                    color:
                        theme.textPrimary
                }

                TextField {

                    id: projectPathField

                    Layout.fillWidth: true

                    Layout.preferredHeight:
                        theme.inputHeight

                    text:
                        backend.projectPath

                    placeholderText:
                        "Select a project folder..."

                    font.family:
                        theme.uiFont

                    font.pixelSize:
                        theme.fontNormal

                    color:
                        theme.textPrimary

                    background: Rectangle {

                        radius:
                            theme.smallRadius

                        color:
                            theme.inputBackground

                        border.color:
                            projectPathField.activeFocus
                            ? theme.accent
                            : theme.inputBorder

                        border.width:
                            projectPathField.activeFocus
                            ? 2
                            : 1
                    }

                    onEditingFinished: {

                        backend.projectPath =
                            text

                        if (
                            text.length === 0
                        ) {

                            statusText.text =
                                "Select project folder"

                            statusText.color =
                                theme.statusNeutral
                        }
                    }
                }

                Button {

                    text:
                        "..."

                    Layout.preferredWidth: 58

                    Layout.preferredHeight:
                        theme.inputHeight

                    font.family:
                        theme.uiFont

                    font.pixelSize: 18

                    background: Rectangle {

                        radius:
                            theme.smallRadius

                        color:
                            parent.pressed
                            ? theme.buttonPressed
                            :
                            parent.hovered
                            ? theme.buttonHover
                            : theme.buttonBackground

                        border.color:
                            parent.hovered
                            ? theme.accent
                            : theme.inputBorder

                        border.width: 1
                    }

                    contentItem: Text {

                        text:
                            parent.text

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter

                        font:
                            parent.font

                        color:
                            theme.buttonText
                    }

                    onClicked: {

                        folderDialog.open()
                    }
                }
            }
        }

        // =====================================================
        // Processing Rules
        // =====================================================

        Rectangle {

            Layout.fillWidth: true

            Layout.preferredHeight: 218

            radius:
                theme.radius

            color:
                theme.cardBackground

            border.color:
                theme.cardBorder

            border.width: 1

            ColumnLayout {

                anchors.fill: parent

                anchors.leftMargin:
                    theme.cardPadding

                anchors.rightMargin:
                    theme.cardPadding

                anchors.topMargin: 12

                anchors.bottomMargin: 12

                spacing: 9

                // -------------------------------------------------
                // Rules Header
                // -------------------------------------------------

                RowLayout {

                    Layout.fillWidth: true

                    Layout.preferredHeight: 38

                    Label {

                        text:
                            "Processing Rules"

                        font.family:
                            theme.uiFont

                        font.pixelSize:
                            theme.fontSection

                        font.bold: true

                        color:
                            theme.textPrimary
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // =================================================
                    // Preset ComboBox
                    // =================================================

                    ComboBox {

                        id: presetCombo

                        Layout.preferredWidth: 180

                        Layout.preferredHeight:
                            theme.buttonHeight

                        model:
                            backend.presetNames

                        currentIndex: -1

                        font.family:
                            theme.uiFont

                        font.pixelSize:
                            theme.fontSmall

                        displayText:
                            currentIndex >= 0
                            ? currentText
                            : "Add preset..."

                        contentItem: Text {

                            leftPadding: 12

                            rightPadding: 30

                            text:
                                presetCombo.displayText

                            verticalAlignment:
                                Text.AlignVCenter

                            elide:
                                Text.ElideRight

                            font.family:
                                theme.uiFont

                            font.pixelSize:
                                theme.fontSmall

                            color:
                                theme.textPrimary
                        }

                        background: Rectangle {

                            radius:
                                theme.smallRadius

                            color:
                                presetCombo.pressed
                                ? theme.buttonPressed
                                :
                                presetCombo.hovered
                                ? theme.comboHover
                                : theme.comboBackground

                            border.color:
                                presetCombo.activeFocus
                                ? theme.accent
                                : theme.inputBorder

                            border.width:
                                presetCombo.activeFocus
                                ? 2
                                : 1
                        }

                        indicator: Canvas {

                            x:
                                presetCombo.width
                                - width
                                - 10

                            y:
                                (
                                    presetCombo.height
                                    - height
                                ) / 2

                            width: 12

                            height: 8

                            onPaint: {

                                var ctx =
                                    getContext("2d")

                                ctx.clearRect(
                                    0,
                                    0,
                                    width,
                                    height
                                )

                                ctx.strokeStyle =
                                    theme.textSecondary

                                ctx.lineWidth = 1.8

                                ctx.lineCap =
                                    "round"

                                ctx.beginPath()

                                ctx.moveTo(1, 2)

                                ctx.lineTo(6, 7)

                                ctx.lineTo(11, 2)

                                ctx.stroke()
                            }
                        }

                        popup: Popup {

                            y:
                                presetCombo.height + 4

                            width:
                                presetCombo.width

                            padding: 4

                            background: Rectangle {

                                radius:
                                    theme.smallRadius

                                color:
                                    theme.comboPopupBackground

                                border.color:
                                    theme.cardBorder

                                border.width: 1
                            }

                            contentItem: ListView {

                                clip: true

                                implicitHeight:
                                    Math.min(
                                        contentHeight,
                                        260
                                    )

                                model:
                                    presetCombo.delegateModel

                                ScrollIndicator.vertical:
                                    ScrollIndicator {}
                            }
                        }

                        delegate: ItemDelegate {

                            width:
                                presetCombo.width - 8

                            height: 38

                            highlighted:
                                presetCombo.highlightedIndex
                                === index

                            contentItem: Text {

                                leftPadding: 10

                                text:
                                    modelData

                                verticalAlignment:
                                    Text.AlignVCenter

                                font.family:
                                    theme.uiFont

                                font.pixelSize:
                                    theme.fontSmall

                                color:
                                    theme.textPrimary
                            }

                            background: Rectangle {

                                radius: 5

                                color:
                                    highlighted
                                    ? theme.comboPopupHover
                                    : "transparent"
                            }
                        }
                    }

                    // =================================================
                    // Add
                    // =================================================

                    Button {

                        text:
                            "Add"

                        Layout.preferredWidth: 70

                        Layout.preferredHeight:
                            theme.buttonHeight

                        font.family:
                            theme.uiFont

                        font.pixelSize:
                            theme.fontSmall

                        font.bold: true

                        enabled:
                            presetCombo.currentIndex >= 0

                        background: Rectangle {

                            radius:
                                theme.smallRadius

                            color:
                                !parent.enabled
                                ? theme.buttonDisabled
                                :
                                parent.pressed
                                ? theme.accentDark
                                :
                                parent.hovered
                                ? theme.accentDark
                                : theme.accent
                        }

                        contentItem: Text {

                            text:
                                parent.text

                            horizontalAlignment:
                                Text.AlignHCenter

                            verticalAlignment:
                                Text.AlignVCenter

                            font:
                                parent.font

                            color:
                                parent.enabled
                                ? "white"
                                : theme.buttonTextDisabled
                        }

                        onClicked: {

                            backend.addPreset(
                                presetCombo.currentText
                            )

                            presetCombo.currentIndex =
                                -1
                        }
                    }

                    // =================================================
                    // Clear
                    // =================================================

                    Button {

                        text:
                            "Clear"

                        Layout.preferredWidth: 70

                        Layout.preferredHeight:
                            theme.buttonHeight

                        font.family:
                            theme.uiFont

                        font.pixelSize:
                            theme.fontSmall

                        background: Rectangle {

                            radius:
                                theme.smallRadius

                            color:
                                parent.pressed
                                ? theme.buttonPressed
                                :
                                parent.hovered
                                ? theme.buttonHover
                                : theme.buttonBackground

                            border.color:
                                parent.hovered
                                ? theme.accent
                                : theme.inputBorder

                            border.width: 1
                        }

                        contentItem: Text {

                            text:
                                parent.text

                            horizontalAlignment:
                                Text.AlignHCenter

                            verticalAlignment:
                                Text.AlignVCenter

                            font:
                                parent.font

                            color:
                                theme.buttonText
                        }

                        onClicked: {

                            backend.clearRules()
                        }
                    }
                }

                // -------------------------------------------------
                // Rules Fields
                // -------------------------------------------------

                GridLayout {

                    Layout.fillWidth: true

                    Layout.fillHeight: true

                    columns: 2

                    columnSpacing: 14

                    rowSpacing: 7

                    Label {

                        text:
                            "Exclude directories"

                        Layout.preferredWidth: 155

                        font.family:
                            theme.uiFont

                        font.pixelSize:
                            theme.fontSmall

                        color:
                            theme.textSecondary
                    }

                    TextField {

                        id: excludeDirsField

                        Layout.fillWidth: true

                        Layout.preferredHeight: 34

                        text:
                            backend.excludeDirs

                        font.family:
                            theme.uiFont

                        font.pixelSize:
                            theme.fontSmall

                        color:
                            theme.textPrimary

                        background: Rectangle {

                            radius:
                                theme.smallRadius

                            color:
                                theme.inputBackground

                            border.color:
                                excludeDirsField.activeFocus
                                ? theme.accent
                                : theme.inputBorder

                            border.width:
                                excludeDirsField.activeFocus
                                ? 2
                                : 1
                        }

                        onEditingFinished: {

                            backend.setExcludeDirs(
                                text
                            )
                        }
                    }

                    Label {

                        text:
                            "Exclude files"

                        Layout.preferredWidth: 155

                        font.family:
                            theme.uiFont

                        font.pixelSize:
                            theme.fontSmall

                        color:
                            theme.textSecondary
                    }

                    TextField {

                        id: excludeFilesField

                        Layout.fillWidth: true

                        Layout.preferredHeight: 34

                        text:
                            backend.excludeFiles

                        font.family:
                            theme.uiFont

                        font.pixelSize:
                            theme.fontSmall

                        color:
                            theme.textPrimary

                        background: Rectangle {

                            radius:
                                theme.smallRadius

                            color:
                                theme.inputBackground

                            border.color:
                                excludeFilesField.activeFocus
                                ? theme.accent
                                : theme.inputBorder

                            border.width:
                                excludeFilesField.activeFocus
                                ? 2
                                : 1
                        }

                        onEditingFinished: {

                            backend.setExcludeFiles(
                                text
                            )
                        }
                    }

                    Label {

                        text:
                            "Content extensions"

                        Layout.preferredWidth: 155

                        font.family:
                            theme.uiFont

                        font.pixelSize:
                            theme.fontSmall

                        color:
                            theme.textSecondary
                    }

                    TextField {

                        id: extensionsField

                        Layout.fillWidth: true

                        Layout.preferredHeight: 34

                        text:
                            backend.contentExtensions

                        font.family:
                            theme.uiFont

                        font.pixelSize:
                            theme.fontSmall

                        color:
                            theme.textPrimary

                        background: Rectangle {

                            radius:
                                theme.smallRadius

                            color:
                                theme.inputBackground

                            border.color:
                                extensionsField.activeFocus
                                ? theme.accent
                                : theme.inputBorder

                            border.width:
                                extensionsField.activeFocus
                                ? 2
                                : 1
                        }

                        onEditingFinished: {

                            backend.setContentExtensions(
                                text
                            )
                        }
                    }

                    Label {

                        text:
                            "Content files"

                        Layout.preferredWidth: 155

                        font.family:
                            theme.uiFont

                        font.pixelSize:
                            theme.fontSmall

                        color:
                            theme.textSecondary
                    }

                    TextField {

                        id: contentFilesField

                        Layout.fillWidth: true

                        Layout.preferredHeight: 34

                        text:
                            backend.contentFiles

                        font.family:
                            theme.uiFont

                        font.pixelSize:
                            theme.fontSmall

                        color:
                            theme.textPrimary

                        background: Rectangle {

                            radius:
                                theme.smallRadius

                            color:
                                theme.inputBackground

                            border.color:
                                contentFilesField.activeFocus
                                ? theme.accent
                                : theme.inputBorder

                            border.width:
                                contentFilesField.activeFocus
                                ? 2
                                : 1
                        }

                        onEditingFinished: {

                            backend.setContentFiles(
                                text
                            )
                        }
                    }
                }
            }
        }

        // =====================================================
        // Tabs
        // =====================================================

        TabBar {

            id: tabBar

            Layout.fillWidth: true

            Layout.preferredHeight: 50

            spacing: 5

            background: Rectangle {
                color:
                    "transparent"
            }

            TabButton {

                text:
                    "Project Tree"

                Layout.preferredWidth: 155

                Layout.preferredHeight: 48

                font.family:
                    theme.uiFont

                font.pixelSize:
                    theme.fontNormal

                font.bold: true

                contentItem: Text {

                    text:
                        parent.text

                    horizontalAlignment:
                        Text.AlignHCenter

                    verticalAlignment:
                        Text.AlignVCenter

                    font:
                        parent.font

                    color:
                        tabBar.currentIndex === 0
                        ? theme.tabActiveText
                        : theme.tabInactiveText
                }

                background: Rectangle {

                    radius:
                        theme.smallRadius

                    color:
                        tabBar.currentIndex === 0
                        ? theme.tabActiveBackground
                        : "transparent"

                    border.color:
                        tabBar.currentIndex === 0
                        ? theme.cardBorder
                        : "transparent"

                    border.width: 1
                }
            }

            TabButton {

                text:
                    "Proj Contents"

                Layout.preferredWidth: 170

                Layout.preferredHeight: 48

                font.family:
                    theme.uiFont

                font.pixelSize:
                    theme.fontNormal

                font.bold: true

                contentItem: Text {

                    text:
                        parent.text

                    horizontalAlignment:
                        Text.AlignHCenter

                    verticalAlignment:
                        Text.AlignVCenter

                    font:
                        parent.font

                    color:
                        tabBar.currentIndex === 1
                        ? theme.tabActiveText
                        : theme.tabInactiveText
                }

                background: Rectangle {

                    radius:
                        theme.smallRadius

                    color:
                        tabBar.currentIndex === 1
                        ? theme.tabActiveBackground
                        : "transparent"

                    border.color:
                        tabBar.currentIndex === 1
                        ? theme.cardBorder
                        : "transparent"

                    border.width: 1
                }
            }

            TabButton {

                text:
                    "Statistics"

                Layout.preferredWidth: 135

                Layout.preferredHeight: 48

                font.family:
                    theme.uiFont

                font.pixelSize:
                    theme.fontNormal

                font.bold: true

                contentItem: Text {

                    text:
                        parent.text

                    horizontalAlignment:
                        Text.AlignHCenter

                    verticalAlignment:
                        Text.AlignVCenter

                    font:
                        parent.font

                    color:
                        tabBar.currentIndex === 2
                        ? theme.tabActiveText
                        : theme.tabInactiveText
                }

                background: Rectangle {

                    radius:
                        theme.smallRadius

                    color:
                        tabBar.currentIndex === 2
                        ? theme.tabActiveBackground
                        : "transparent"

                    border.color:
                        tabBar.currentIndex === 2
                        ? theme.cardBorder
                        : "transparent"

                    border.width: 1
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        // =====================================================
        // Tab Contents
        // =====================================================

        StackLayout {

            id: tabContent

            Layout.fillWidth: true

            Layout.fillHeight: true

            currentIndex:
                tabBar.currentIndex

            // =================================================
            // Project Tree
            // =================================================

            Rectangle {

                color:
                    theme.cardBackground

                radius:
                    theme.radius

                border.color:
                    theme.cardBorder

                border.width: 1

                ScrollView {

                    anchors.fill: parent

                    anchors.margins: 14

                    clip: true

                    TextArea {

                        text:
                            backend.tree

                        readOnly: true

                        selectByMouse: true

                        wrapMode:
                            TextArea.NoWrap

                        font.family:
                            "monospace"

                        font.pixelSize:
                            theme.fontCode

                        color:
                            theme.textPrimary

                        background:
                            null

                        placeholderText:
                            "Project tree will appear here after processing."
                    }
                }
            }

            // =================================================
            // Proj Contents
            // =================================================

            Rectangle {

                id: contentsTab

                color:
                    theme.cardBackground

                radius:
                    theme.radius

                border.color:
                    theme.cardBorder

                border.width: 1

                ColumnLayout {

                    anchors.fill: parent

                    anchors.margins: 14

                    spacing: 9

                    // -----------------------------------------
                    // Navigation
                    // -----------------------------------------

                    RowLayout {

                        Layout.fillWidth: true

                        Layout.preferredHeight: 40

                        // -------------------------------------
                        // Previous
                        // -------------------------------------

                        Loader {

                            Layout.preferredWidth: 112

                            Layout.preferredHeight: 38

                            sourceComponent:
                                navigationButton

                            onLoaded: {

                                item.text =
                                    "← Previous"

                                item.enabled =
                                    Qt.binding(
                                        function() {
                                            return backend.canPrevious
                                        }
                                    )

                                item.clicked.connect(
                                    function() {
                                        backend.previousFile()
                                    }
                                )
                            }
                        }

                        // -------------------------------------
                        // First
                        // -------------------------------------

                        Loader {

                            Layout.preferredWidth: 82

                            Layout.preferredHeight: 38

                            sourceComponent:
                                navigationButton

                            onLoaded: {

                                item.text =
                                    "⏮ First"

                                item.enabled =
                                    Qt.binding(
                                        function() {
                                            return backend.canPrevious
                                        }
                                    )

                                item.clicked.connect(
                                    function() {
                                        backend.firstFile()
                                    }
                                )
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        // -------------------------------------
                        // Counter
                        // -------------------------------------

                        Label {

                            text:
                                backend.fileCount > 0
                                ? (
                                    (
                                        backend.currentFileIndex
                                        + 1
                                    )
                                    + " / "
                                    + backend.fileCount
                                )
                                : "0 / 0"

                            font.family:
                                theme.uiFont

                            font.pixelSize:
                                theme.fontSmall

                            font.bold: true

                            color:
                                theme.textSecondary
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        // -------------------------------------
                        // Last
                        // -------------------------------------

                        Loader {

                            Layout.preferredWidth: 82

                            Layout.preferredHeight: 38

                            sourceComponent:
                                navigationButton

                            onLoaded: {

                                item.text =
                                    "Last ⏭"

                                item.enabled =
                                    Qt.binding(
                                        function() {
                                            return backend.canNext
                                        }
                                    )

                                item.clicked.connect(
                                    function() {
                                        backend.lastFile()
                                    }
                                )
                            }
                        }

                        // -------------------------------------
                        // Next
                        // -------------------------------------

                        Loader {

                            Layout.preferredWidth: 112

                            Layout.preferredHeight: 38

                            sourceComponent:
                                navigationButton

                            onLoaded: {

                                item.text =
                                    "Next →"

                                item.enabled =
                                    Qt.binding(
                                        function() {
                                            return backend.canNext
                                        }
                                    )

                                item.clicked.connect(
                                    function() {
                                        backend.nextFile()
                                    }
                                )
                            }
                        }
                    }

                    // -----------------------------------------
                    // Current File
                    // -----------------------------------------

                    Rectangle {

                        Layout.fillWidth: true

                        Layout.preferredHeight: 40

                        radius:
                            theme.smallRadius

                        color:
                            "#f5f7f9"

                        border.color:
                            "#e0e4e8"

                        border.width: 1

                        Label {

                            anchors.fill: parent

                            anchors.leftMargin: 11

                            anchors.rightMargin: 11

                            verticalAlignment:
                                Text.AlignVCenter

                            text:
                                backend.currentFilePath !== ""
                                ? backend.currentFilePath
                                : "No file selected"

                            elide:
                                Text.ElideMiddle

                            font.family:
                                "monospace"

                            font.pixelSize:
                                theme.fontTiny

                            color:
                                theme.textSecondary
                        }
                    }

                    // -----------------------------------------
                    // Complete File Contents
                    // -----------------------------------------

                    Rectangle {

                        Layout.fillWidth: true

                        Layout.fillHeight: true

                        radius:
                            theme.smallRadius

                        color:
                            "#fafbfc"

                        border.color:
                            "#e0e4e8"

                        border.width: 1

                        ScrollView {

                            id: contentsScrollView

                            anchors.fill: parent

                            anchors.margins: 8

                            clip: true

                            ScrollBar.vertical.policy:
                                ScrollBar.AsNeeded

                            TextArea {

                                id: allContentsText

                                width:
                                    contentsScrollView.availableWidth

                                text:
                                    backend.allContents

                                readOnly: true

                                selectByMouse: true

                                wrapMode:
                                    TextArea.NoWrap

                                textFormat:
                                    TextEdit.PlainText

                                font.family:
                                    "monospace"

                                font.pixelSize:
                                    theme.fontCode

                                color:
                                    theme.textPrimary

                                background:
                                    null

                                placeholderText:
                                    "File contents will appear here."

                                onTextChanged: {

                                    Qt.callLater(
                                        contentsTab
                                        .scrollToCurrentFile
                                    )
                                }
                            }
                        }
                    }
                }

                // =================================================
                // Smooth Scroll
                // =================================================

                NumberAnimation {

                    id: smoothScrollAnimation

                    target:
                        contentsScrollView.contentItem

                    property:
                        "contentY"

                    duration: 450

                    easing.type:
                        Easing.InOutCubic
                }

                // =================================================
                // Scroll To Current File
                // =================================================

                function scrollToCurrentFile() {

                    if (
                        backend.fileCount <= 0
                    )
                        return

                    var position =
                        backend.currentFilePosition

                    if (
                        position < 0
                    )
                        return

                    var rect =
                        allContentsText
                        .positionToRectangle(
                            position
                        )

                    var targetY =
                        Math.max(
                            0,
                            rect.y - 20
                        )

                    var maxY =
                        Math.max(
                            0,
                            contentsScrollView
                            .contentItem
                            .contentHeight
                            -
                            contentsScrollView.height
                        )

                    targetY =
                        Math.min(
                            targetY,
                            maxY
                        )

                    smoothScrollAnimation.stop()

                    smoothScrollAnimation.from =
                        contentsScrollView
                        .contentItem
                        .contentY

                    smoothScrollAnimation.to =
                        targetY

                    smoothScrollAnimation.start()
                }

                // =================================================
                // Backend Navigation Signals
                // =================================================

                Connections {

                    target:
                        backend

                    function onCurrentFileChanged() {

                        if (
                            tabBar.currentIndex !== 1
                        ) {
                            return
                        }

                        Qt.callLater(
                            contentsTab
                            .scrollToCurrentFile
                        )
                    }

                    function onFilesChanged() {

                        Qt.callLater(
                            contentsTab
                            .scrollToCurrentFile
                        )
                    }
                }
            }

            // =================================================
            // Statistics
            // =================================================

            Rectangle {

                color:
                    theme.cardBackground

                radius:
                    theme.radius

                border.color:
                    theme.cardBorder

                border.width: 1

                ScrollView {

                    anchors.fill: parent

                    anchors.margins: 16

                    clip: true

                    TextArea {

                        text:
                            backend.statistics

                        readOnly: true

                        selectByMouse: true

                        font.family:
                            theme.uiFont

                        font.pixelSize:
                            theme.fontNormal

                        color:
                            theme.textPrimary

                        background:
                            null

                        placeholderText:
                            "Statistics will appear here after processing."
                    }
                }
            }
        }

        // =====================================================
        // Bottom Status Bar
        // =====================================================

        Rectangle {

            Layout.fillWidth: true

            Layout.preferredHeight: 42

            color:
                "transparent"

            RowLayout {

                anchors.fill: parent

                spacing: 9

                // -------------------------------------------------
                // Status Indicator
                // -------------------------------------------------

                Rectangle {

                    Layout.preferredWidth: 8

                    Layout.preferredHeight: 8

                    radius: 4

                    color:
                        statusText.color
                }

                Label {

                    id: statusText

                    text:
                        backend.projectPath.length > 0
                        ? "Ready"
                        : "Select project folder"

                    font.family:
                        theme.uiFont

                    font.pixelSize:
                        theme.fontSmall

                    color:
                        backend.projectPath.length > 0
                        ? theme.statusReady
                        : theme.statusNeutral
                }

                Item {
                    Layout.fillWidth: true
                }

                // -------------------------------------------------
                // Process / Cancel
                // -------------------------------------------------

                Button {

                    id: processButton

                    text:
                        backend.processing
                        ? "Cancel"
                        : "Process"

                    Layout.preferredWidth: 130

                    Layout.preferredHeight: 42

                    font.family:
                        theme.uiFont

                    font.pixelSize:
                        theme.fontNormal

                    font.bold: true

                    enabled:
                        backend.processing
                        ||
                        backend.projectPath.length > 0

                    background: Rectangle {

                        radius:
                            theme.smallRadius

                        color:
                            !parent.enabled
                            ? "#dfe2e6"
                            :
                            backend.processing
                            ? (
                                parent.pressed
                                ? "#963f3d"
                                :
                                parent.hovered
                                ? "#a94745"
                                : "#bd5754"
                            )
                            :
                            (
                                parent.pressed
                                ? theme.accentDark
                                :
                                parent.hovered
                                ? theme.accentDark
                                : theme.accent
                            )
                    }

                    contentItem: Text {

                        text:
                            parent.text

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter

                        font:
                            parent.font

                        color:
                            parent.enabled
                            ? "white"
                            : "#9299a1"
                    }

                    onClicked: {

                        if (
                            backend.processing
                        ) {

                            backend.cancel()

                            statusText.text =
                                "Cancelling..."

                            statusText.color =
                                theme.statusProcessing

                        } else {

                            backend.process()

                            statusText.text =
                                "Processing..."

                            statusText.color =
                                theme.statusProcessing
                        }
                    }
                }
            }
        }
    }
}