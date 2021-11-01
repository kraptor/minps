# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strutils

include inc/imports
import state
import mainmenu
import fonts
import actions

import cpu_debugger
import cpu_registers
import cop0_registers

logChannels ["gui", "app"]

type
    Application* = object
        state*: State


proc New*(t: type Application, config: var Config, platform: var Platform): Application =
    result.state.config = config
    result.state.platform = platform

    notice "Initializing glfw..."
    logIndent:
        if not glfwInit():
            error "Can't initialize GLFW!"
            quit(-1)
        notice "done."

    notice "Initializing window..."
    logIndent:
        glfwWindowHint(GLFWContextVersionMajor, 3)
        glfwWindowHint(GLFWContextVersionMinor, 3)
        glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
        glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
        glfwWindowHint(GLFWResizable, GLFW_FALSE)
        
        result.state.window = glfwCreateWindow(
            config.gui.window_width, 
            config.gui.window_height, 
            "minps - version: " & VersionString
        )

        if result.state.window == nil:
            error "Can't create window!"
            quit(-1)
        
        setWindowUserPointer(result.state.window, result.addr)
        
        result.state.window.makeContextCurrent()
        notice "done."

    notice "Initializing OpenGL..."
    logIndent:
        if not glInit():
            error "Can't initialize OpenGL!"
            quit(-1)

    notice "Initialize Imgui..."
    result.state.context = igCreateContext()
    if not igGlfwInitForOpenGL(result.state.window, true):
        error "Can't initialize Imgui!"
        quit(-1)
    
    if not igOpenGL3Init():
        error "Can't initialize Imgui OpenGL!"
    igStyleColorsCherry()

    debug "Setting up key callback..."
    discard setKeyCallback(result.state.window, glfwKeyCallback)

    # load fonts
    LoadDefaultFont()
    LoadFont("ui", config.gui.ui_font)
    LoadFont("mono", config.gui.mono_font)


proc Terminate*(app: var Application) =
    notice "Terminating application..."
    logIndent:
        # imgui
        igOpenGL3Shutdown()
        igGlfwShutdown()
        app.state.context.igDestroyContext()
        
        # glfw
        destroyWindow app.state.window
        glfwTerminate()
        notice "done."


proc GetShortcut(key, mods, action: int32): string =
    if action == GLFWRelease:
        return ""

    let
        is_shift = (mods and GLFWModShift) == GLFWModShift
        is_ctrl = (mods and GLFWModControl) == GLFWModControl
        is_super = (mods and GLFWModSuper) == GLFWModSuper
        is_alt = (mods and GLFWModAlt) == GLFWModAlt

    # # shortcuts need a modifier
    # if not(is_shift or is_ctrl or is_super or is_alt):
    #     return ""

    var shortcut: seq[string]
    if is_shift: shortcut.add("shift")
    if is_ctrl: shortcut.add("ctrl")
    if is_super: shortcut.add("super")
    if is_alt: shortcut.add("alt")

    # FIXME: fix "enum with holes is unsafe" warning
    shortcut.add($(key.GLFWKey))

    return shortcut.join("+")


proc glfwKeyCallback(window: GLFWWindow, key: int32, scancode: int32, action_press: int32, mods: int32): void {.cdecl.} =
    var app = cast[ref Application](window.getWindowUserPointer())
    let shortcut = GetShortcut(key, mods, action_press)

    if shortcut != "":
        var action = GetActionByShortcut(shortcut)
        if action == NO_ACTION:
            debug "Shortcut ignored: " & shortcut
        action.Run(app.state)


proc Draw*(app: var Application) =
    block background:
        glClearColor(0, 0, 0, 1)
        glClear(GL_COLOR_BUFFER_BIT)

    block user_interface:
        igOpenGL3NewFrame()
        igGlfwNewFrame()
        igNewFrame()

        igPushFont(GetFont("ui"))

        block draw_gui:
            mainmenu.Draw(app.state)
            cpu_debugger.Draw(app.state)
            cpu_registers.Draw(app.state)
            cop0_registers.Draw(app.state)

        igPopFont()

        igRender()
        igOpenGL3RenderDrawData(igGetDrawData())


proc ProcessEvents*(app: var Application) =
    glfwPollEvents()


proc IsClosing*(app: var Application): bool =
    app.state.window.windowShouldClose()


proc Present*(app: var Application) =
    app.state.window.swapBuffers()
