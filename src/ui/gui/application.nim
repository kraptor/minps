# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import nimgl/[glfw, opengl]
import nimgl/imgui, nimgl/imgui/[impl_opengl, impl_glfw]

import ../../core/log
import ../../core/config
import ../../core/version

logChannels ["gui", "app"]

type
    Application* = object
        window: GLFWWindow
        context: ptr ImGuiContext


proc New*(t: type Application, config: var Config): Application =    
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

        echo $config.gui.window_width 
        echo $config.gui.window_height

        result.window = glfwCreateWindow(
            config.gui.window_width, 
            config.gui.window_height, 
            "minps - version: " & VersionString
        )

        if result.window == nil:
            error "Can't create window!"
            quit(-1)
        
        result.window.makeContextCurrent()
        notice "done."

    notice "Initializing OpenGL..."
    logIndent:
        if not glInit():
            error "Can't initialize OpenGL!"
            quit(-1)

    notice "Initialize Imgui..."
    result.context = igCreateContext()
    if not igGlfwInitForOpenGL(result.window, true):
        error "Can't initialize Imgui!"
        quit(-1)
    
    if not igOpenGL3Init():
        error "Can't initialize Imgui OpenGL!"
    igStyleColorsCherry()

    debug "Setting up key callback..."
    discard setKeyCallback(result.window, glfwKeyCallback)


proc Terminate*(app: var Application) =
    notice "Terminating application..."
    logIndent:
        # imgui
        igOpenGL3Shutdown()
        igGlfwShutdown()
        app.context.igDestroyContext()
        
        # glfw
        destroyWindow app.window
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
        #igShowDemoWindow()

        igRender()
        igOpenGL3RenderDrawData(igGetDrawData())


proc ProcessEvents*(app: var Application) =
    glfwPollEvents()


proc IsClosing*(app: var Application): bool =
    app.window.windowShouldClose()


proc Present*(app: var Application) =
    app.window.swapBuffers()


proc glfwKeyCallback(window: GLFWWindow, key: int32, scancode: int32, action: int32, mods: int32): void {.cdecl.} =
    if key == GLFWKey.ESCAPE and action == GLFWPress:
        window.setWindowShouldClose(true)