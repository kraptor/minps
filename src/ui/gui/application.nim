# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

include inc/imports
import state
import mainmenu
import debugger
import fonts

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


proc Draw*(app: var Application) =
    block background:
        glClearColor(0, 0, 0, 1)
        glClear(GL_COLOR_BUFFER_BIT)

    block user_interface:
        igOpenGL3NewFrame()
        igGlfwNewFrame()
        igNewFrame()
        
        # TODO: draw here user interface
        mainmenu.Draw(app.state)
        debugger.Draw(app.state)

        igRender()
        igOpenGL3RenderDrawData(igGetDrawData())


proc ProcessEvents*(app: var Application) =
    glfwPollEvents()


proc IsClosing*(app: var Application): bool =
    app.state.window.windowShouldClose()


proc Present*(app: var Application) =
    app.state.window.swapBuffers()


proc glfwKeyCallback(window: GLFWWindow, key: int32, scancode: int32, action: int32, mods: int32): void {.cdecl.} =
    if key == GLFWKey.ESCAPE and action == GLFWPress:
        window.setWindowShouldClose(true)