' Replace pythonPath with the output of: py -c "import sys; print(sys.executable)"
' Update scriptPath and logPath if your folder differs from D:\IndexTranslate.
' Stop any existing proxy before starting this template.
Set shell = CreateObject("WScript.Shell")
q = Chr(34)

pythonPath = "C:\YOUR_PYTHON_PATH\python.exe"
scriptPath = "D:\IndexTranslate\call_api.py"
logPath = "D:\IndexTranslate\proxy.log"

cmd = "cmd.exe /c " & q & q & pythonPath & q & " " & q & scriptPath & q & " --serve >> " & q & logPath & q & " 2>&1" & q
shell.Run cmd, 0, False
