VERSION 5.00
Begin VB.Form frmVfcMain 
   BorderStyle     =   1  'Fixed Single
   ClientHeight    =   4740
   ClientLeft      =   45
   ClientTop       =   270
   ClientWidth     =   5280
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   4740
   ScaleWidth      =   5280
   StartUpPosition =   1  'CenterOwner
   Tag             =   "VFC"
   Begin VB.ListBox lstVBProjects 
      Columns         =   2
      Height          =   1320
      IntegralHeight  =   0   'False
      Left            =   120
      TabIndex        =   0
      Top             =   360
      Width           =   5040
   End
   Begin VB.CommandButton cmdCancel 
      Cancel          =   -1  'True
      Caption         =   "Exit"
      Height          =   375
      Left            =   3480
      TabIndex        =   2
      Top             =   4080
      Width           =   960
   End
   Begin VB.Frame fraOptions 
      Caption         =   "Convert Forms"
      BeginProperty Font 
         Name            =   "Tahoma"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   2160
      Left            =   120
      TabIndex        =   3
      Top             =   1800
      Width           =   5040
      Begin VB.CheckBox chkIncludeCode 
         Caption         =   "Include Code in UserForm Export"
         Height          =   300
         Left            =   150
         TabIndex        =   5
         Top             =   240
         Value           =   1  'Checked
         Width           =   4710
      End
      Begin VB.CheckBox chkShowUnknown 
         Caption         =   "Show Placeholders for Unknown Controls"
         Height          =   300
         Left            =   150
         TabIndex        =   6
         Top             =   600
         Value           =   1  'Checked
         Width           =   4830
      End
      Begin VB.Frame Frame1 
         Caption         =   "Git Repository Root"
         Height          =   720
         Left            =   150
         TabIndex        =   7
         Top             =   1320
         Width           =   4800
         Begin VB.TextBox txtGitRepoPath 
            Alignment       =   1  'Right Justify
            Height          =   360
            Left            =   150
            Locked          =   -1  'True
            TabIndex        =   8
            TabStop         =   0   'False
            Top             =   240
            Width           =   3600
         End
         Begin VB.CommandButton cmdBrowseRepo 
            Caption         =   "Browse"
            Height          =   360
            Left            =   3750
            TabIndex        =   9
            Top             =   240
            Width           =   960
         End
      End
      Begin VB.CheckBox cbDeleteIgnoreFiles 
         Caption         =   "Delete files in /ignore/ after processing"
         Height          =   300
         Left            =   150
         TabIndex        =   10
         Top             =   960
         Value           =   1  'Checked
         Width           =   4830
      End
   End
   Begin VB.CommandButton cmdConvert 
      Caption         =   "Export Project for Source Control"
      Enabled         =   0   'False
      Height          =   375
      Left            =   600
      TabIndex        =   4
      Top             =   4080
      Width           =   2760
   End
   Begin VB.Label lblProject 
      Caption         =   "Select Project:"
      BeginProperty Font 
         Name            =   "Tahoma"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   240
      Left            =   240
      TabIndex        =   1
      Top             =   120
      Width           =   2880
   End
End
Attribute VB_Name = "frmVfcMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

Option Explicit

Public Property Get SelectedProjectIndex() As Long
  If lstVBProjects.listIndex > -1 Then
    SelectedProjectIndex = CLng(lstVBProjects.Text)
  End If
End Property

Public Property Get SelectedProjectFilename() As String
  If lstVBProjects.listIndex > -1 Then
    SelectedProjectFilename = lstVBProjects.List(lstVBProjects.listIndex, 2)
  End If
End Property

Public Property Get SelectedProjectGitDirectory() As String
  If lstVBProjects.listIndex > -1 Then
    SelectedProjectGitDirectory = txtGitRepoPath & StripExtensionFromFileName(GetFileNameFromPath(lstVBProjects.List(lstVBProjects.listIndex, 2)))
    If Dir(SelectedProjectGitDirectory, vbDirectory) = "" Then MkDir SelectedProjectGitDirectory
  End If
End Property

Public Property Get SelectedProjectGitIgnoreDirectory() As String
  If lstVBProjects.listIndex > -1 Then
    SelectedProjectGitIgnoreDirectory = SelectedProjectGitDirectory & "\ignore\"
    If Dir(SelectedProjectGitIgnoreDirectory, vbDirectory) = "" Then MkDir SelectedProjectGitIgnoreDirectory
  End If
End Property


Public Property Get IncludeCode() As Boolean
  IncludeCode = (chkIncludeCode.Value = True)
End Property

Public Property Get ShowUnknown() As Boolean
  ShowUnknown = (chkShowUnknown.Value = True)
End Property

Private Sub cmdBrowseRepo_Click()

    txtGitRepoPath = BrowseFolder("Select GIT Repo Base Folder", Environ("USERPROFILE") & "\Source\Repos\Autocad Automation\")
    'MsgBox Environ("USERPROFILE")
    '"C:\Users\acunningham\Source\Repos"
End Sub

Private Sub cmdCancel_Click()
  Unload Me
End Sub

Private Sub cmdConvert_Click()
  cmdCancel.Caption = "Exit"
  Call ProcessProject
  Call ExportSourceFiles(SelectedProjectGitDirectory & "\")
End Sub



Private Sub lstVBProjects_Click()
  Dim objProj As VBIDE.VBProject
  Dim intIndex As Integer
  
  If lstVBProjects.listIndex > -1 Then
    Set objProj = Application.VBE.VBProjects(Me.SelectedProjectIndex)
    cmdConvert.Enabled = True

  End If
  
  Set objProj = Nothing
End Sub



Private Sub UserForm_Activate()
  Dim objProjs As VBProjects
  Dim objProj As VBProject
  Dim intIndex As Integer
  Dim strTemp As String
  
  On Error GoTo ErrorHandler
  
  'Load up list box with VBProjects
  Set objProjs = Application.VBE.VBProjects
  cmdConvert.Enabled = False
'  lstMSForms.Clear
  lstVBProjects.Clear
  lstVBProjects.ColumnCount = 3
  lstVBProjects.ColumnWidths = "20 pt;90 pt;400 pt"
  Dim listIndex As Integer
  listIndex = 1
  For intIndex = 1 To objProjs.Count
    Set objProj = objProjs(intIndex)
    If (objProj.fileName <> objProjs.VBE.ActiveVBProject.fileName) Then  'do not list the exporter macro
        lstVBProjects.AddItem CStr(intIndex)
        lstVBProjects.List(listIndex - 1, 1) = objProj.Name
        lstVBProjects.List(listIndex - 1, 2) = objProj.fileName
        listIndex = listIndex + 1
    End If
  Next intIndex
  txtGitRepoPath = Environ("USERPROFILE") & "\Source\Repos\Autocad Automation\"
  
  
SubExit:
  Set objProj = Nothing
  Set objProjs = Nothing
  Exit Sub
ErrorHandler:
  Select Case Err.Number
    Case 76 'Path not found
      strTemp = "VFC can only work with SAVED projects," & vbCrLf & _
                "please save all newly created projects" & vbCrLf & _
                "and start again."
      Call MsgBox(strTemp, vbCritical, ccAPPNAME)
    Case Else 'Huh??
      strTemp = ccAPPNAME & " ERROR" & vbCrLf & _
                "VFC_001: Error in UserForm_Activate" & vbCrLf & _
                "Description: " & Err.Description & vbCrLf & _
                "Source: " & Err.Source & vbCrLf & _
                "Number: " & CStr(Err.Number) & vbCrLf & _
                "VFC Ver: " & ccAPPVER
      Call MsgBox(strTemp, vbCritical, ccAPPNAME)
  End Select
  Unload Me
  Resume SubExit
End Sub

Private Sub UserForm_Terminate()
  Debug.Print "UserForm_Terminate frmVfcMain"
End Sub


