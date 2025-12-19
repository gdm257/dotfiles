; 自定义的函数写在这个文件里,  然后能在 MyKeymap 中调用

; 使用如下写法，来加载当前目录下的其他 AutoHotKey v2 脚本
; #Include ../data/test.ahk

moveUp(n:=1) {
    SendInput(Format("{Up {1}}", n))
}

moveDown(n:=1) {
    SendInput(Format("{Down {1}}", n))
}

moveToFileBeginning() {
    SendInput("^{Home}")
    return
}

moveToFileEnd() {
    SendInput("^{End}")
    return
}

selectUp(n:=1) {
    SendInput(Format("+{Up {1}}", n))
    return
}

selectDown(n:=1) {
    SendInput(Format("+{Down {1}}", n))
    return
}

enterNextLine() {
    SendInput("{End}{Enter}")
    return
}

cleanCurrentLine() {
    SendInput("{End}+{home}{bs}")
    return
}
