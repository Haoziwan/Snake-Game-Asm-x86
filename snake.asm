;ml /coff snake.asm /link /subsystem:windows

.386
.model flat, stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc ; Include GDI32 library for Rectangle function
includelib gdi32.lib
includelib kernel32.lib
INCLUDE masm32.inc          ; nseed, nrandom
INCLUDELIB masm32.lib

includelib user32.lib
includelib kernel32.lib

.const
    GRID_WIDTH equ 30
    GRID_HEIGHT equ 30
    CELL_SIZE equ 20
    CELL_N equ 900
    TIMER_ID equ 1
    TIMER_INTERVAL equ 150 ; 以毫秒为单位设置定时器间隔

.data
    buffer db 20 dup(?)   
    hInstance dd ?
    hWinMain dd ?
    szClassName db 'MyClass', 0
    szCaptionMain db 'Snake Game', 0
    FORMAT_STRING db "      Score:  %d", 0 
    snakeDirection dd 0
    snakeNewDirection dd 0 ; left 1 right 4 up 2 down 3
    snakeX dd CELL_N dup(14) ; 蛇的 x 坐标数组
    snakeY dd CELL_N dup(29) ; 蛇的 y 坐标数组
    head dd 0 ; 蛇头索引
    tail dd 0 ; 蛇尾索引
    snakeLength dd 1; 蛇的长度
    foodX dd 14
    foodY dd 14



.code
CheckCollision proc uses ebx ecx edx esi edi
    mov esi, 0              ; 初始化循环计数器
    mov edi, head

    ; 获取蛇头的坐标
    mov eax, [offset snakeX + 4*edi] 
    mov ebx, [offset snakeY + 4*edi] 
    mov edi, tail
    ; 循环遍历蛇身部分，检查蛇头是否与蛇身重叠
    .while esi < snakeLength
        ; 跳过蛇头本身
        .if edi != head
            ; 获取蛇身部分的坐标
            mov ecx, [offset snakeX + 4*edi] 
            mov edx, [offset snakeY + 4*edi] 

            ; 如果蛇头的坐标与蛇身某部分的坐标相同，则发生碰撞
            .if eax == ecx && ebx == edx
                mov eax, 1  ; 返回结果 1 表示发生碰撞
                ret
            .endif
        .endif
        add edi, 1
        .if edi == CELL_N
            mov edi, 0
        .endif
        add esi, 1  ; 增加循环计数器
    .endw

    mov eax, 0  ; 返回结果 0 表示未发生碰撞
    ret
CheckCollision endp

UpdateSnake proc uses eax ebx ecx edx esi edi, hWnd:DWORD
LOCAL rect:RECT
    .if snakeNewDirection != 0 ;开始移动
        mov eax, snakeNewDirection 
        
        mov ebx , snakeNewDirection
        add ebx , snakeDirection
        .if ebx != 5 ;不能反向移动
            mov snakeDirection, eax
        .endif

        mov eax, head
        mov ebx, eax 
        add ebx,1 ;head++
        .if ebx == CELL_N
            mov ebx, 0
        .endif
        mov ecx, [offset snakeX + 4*eax] 
        mov edx, [offset snakeY + 4*eax] 
        ;计算下一个坐标
        .if snakeDirection == 1 ;left
            sub ecx, 1
        .elseif snakeDirection == 2 ;up
            sub edx, 1
        .elseif snakeDirection == 3 ;down
            add edx, 1
        .elseif snakeDirection == 4 ;right
            add ecx, 1
        .endif
        ;检查是否撞墙
        .if ecx < 0 || ecx >= GRID_WIDTH || edx < 0 || edx >= GRID_HEIGHT
            invoke KillTimer, hWinMain, TIMER_ID ; 边界触发后，结束定时器
            ; 将整数值转换为字符串
       
            invoke wsprintf, addr buffer, addr FORMAT_STRING, snakeLength
            invoke MessageBox, NULL, addr buffer, addr szCaptionMain, MB_OK
            
            invoke ExitProcess, NULL
        .endif
        mov [offset snakeX + 4*ebx] , ecx
        mov [offset snakeY + 4*ebx] , edx
        mov head, ebx

        .if ecx == foodX && edx ==foodY;吃到食物了
       
            
            ;add length and create new food
            add snakeLength, 1  

            invoke GetTickCount
            invoke nseed, eax                   ; Initialize nrandom_seed
            invoke nrandom, GRID_WIDTH
            mov ebx, eax

            invoke nrandom, GRID_HEIGHT
            mov ecx, eax

            mov foodX, ebx
            mov foodY, ecx
         ;invalid new food block
            mov eax, foodX
            mov ebx, foodY
            imul eax, CELL_SIZE
            imul ebx, CELL_SIZE
            mov ecx, eax
            add ecx, CELL_SIZE
            mov edx, ebx
            add edx, CELL_SIZE
            mov rect.left, eax
            mov rect.top, ebx
            mov rect.right, ecx
            mov rect.bottom, edx
            invoke InvalidateRect, hWnd, addr rect, TRUE


        .elseif
        ;invalid tail
            mov edi, tail
            mov eax, [offset snakeX + 4*edi] 
            mov ebx, [offset snakeY + 4*edi] 
            imul eax, CELL_SIZE
            imul ebx, CELL_SIZE
            mov ecx, eax
            add ecx, CELL_SIZE
            mov edx, ebx
            add edx, CELL_SIZE
           mov rect.left, eax
            mov rect.top, ebx
            mov rect.right, ecx
            mov rect.bottom, edx
            invoke InvalidateRect, hWnd, addr rect, TRUE



            mov eax, tail
            add eax, 1
            .if eax == CELL_N
            mov eax, 0
            .endif
            mov tail, eax
        .endif

        ;检查是否碰到自己
        invoke CheckCollision
        .if eax == 1
            invoke KillTimer, hWinMain, TIMER_ID ; 边界触发后，结束定时器
            ; 将整数值转换为字符串
       
            invoke wsprintf, addr buffer, addr FORMAT_STRING, snakeLength
            invoke MessageBox, NULL, addr buffer, addr szCaptionMain, MB_OK
            
            invoke ExitProcess, NULL
        .endif

        ;invalid蛇头块
        mov edi, head
        mov eax, [offset snakeX + 4*edi] 
        mov ebx, [offset snakeY + 4*edi] 
        imul eax, CELL_SIZE
        imul ebx, CELL_SIZE
        mov ecx, eax
        add ecx, CELL_SIZE
        mov edx, ebx
        add edx, CELL_SIZE
        mov rect.left, eax
        mov rect.top, ebx
        mov rect.right, ecx
        mov rect.bottom, edx
        invoke InvalidateRect, hWnd, addr rect, TRUE

       

    .endif
    ret
UpdateSnake endp



Draw proc uses eax ebx ecx edx esi edi, hDC:DWORD
LOCAL rect:RECT
; Draw grid lines
    mov esi, 0
    .while esi < GRID_HEIGHT
        mov ebx, 0
        .while ebx < GRID_WIDTH
            mov eax, ebx
            imul eax, CELL_SIZE
            mov edx, esi
            imul edx, CELL_SIZE

            ; Calculate coordinates for the cell
            mov ecx, eax               ; Store x-coordinate in ecx
            add ecx, CELL_SIZE         ; Calculate x + CELL_SIZE
            mov edi, edx               ; Store y-coordinate in edi
            add edi, CELL_SIZE         ; Calculate y + CELL_SIZE

            invoke Rectangle, hDC, eax, edx, ecx, edi ; Draw a rectangle for a cell
            add ebx, 1
        .endw
        add esi, 1
    .endw

;draw snake
   mov esi, 0
   mov edi, tail
    .while esi < snakeLength

        mov eax, [offset snakeX + 4*edi] 
        mov ebx, [offset snakeY + 4*edi] 
        imul eax, CELL_SIZE
        imul ebx, CELL_SIZE
        mov ecx, eax
        add ecx, CELL_SIZE
        mov edx, ebx
        add edx, CELL_SIZE
               

        ; 指定矩形的位置和大小
        mov rect.left, eax
        mov rect.top, ebx
        mov rect.right, ecx
        mov rect.bottom, edx

        invoke CreateSolidBrush, 00FF0000h
        invoke FillRect, hDC, ADDR rect, eax ; 在指定位置和大小绘制矩形

        add edi, 1
        .if edi == CELL_N
            mov edi, 0
        .endif
        add esi, 1
    .endw


;draw food
    mov eax, foodX
    mov ebx, foodY
    imul eax, CELL_SIZE
    imul ebx, CELL_SIZE
    mov ecx, eax
    add ecx, CELL_SIZE
    mov edx, ebx
    add edx, CELL_SIZE
    
    mov rect.left, eax
    mov rect.top, ebx
    mov rect.right, ecx
    mov rect.bottom, edx

    invoke CreateSolidBrush, 0000FF00h   
    invoke FillRect, hDC, ADDR rect, eax ; 在指定位置和大小绘制矩形
    ret
Draw endp

_ProcWinMain proc uses ebx ecx edx edi esi, hWnd, uMsg, wParam, lParam
    local @stPs: PAINTSTRUCT
    local @stRect: RECT
    local @hDc
    mov eax, uMsg
    .if eax == WM_PAINT
    invoke BeginPaint, hWnd, addr @stPs
    mov @hDc, eax
    
    
    invoke Draw, @hDc; 绘制蛇的每个部分


    invoke EndPaint, hWnd, addr @stPs
    .elseif eax == WM_TIMER
        
        ; 处理定时器消息，更新蛇的位置并重新渲染窗口
        invoke UpdateSnake,hWnd  ; 更新蛇的位置

        ;invoke InvalidateRect, hWnd, NULL, TRUE
        invoke UpdateWindow, hWnd

    .elseif eax == WM_KEYDOWN
        ; 处理键盘输入
        mov eax, wParam ; 将按键的虚拟键码值（键盘输入）放入 eax 中
        .if eax == VK_LEFT ; 按下左箭头键
            mov snakeNewDirection, 1 ; 设置蛇的新方向为左
        .elseif eax == VK_UP ; 按下上箭头键
            mov snakeNewDirection, 2 ; 设置蛇的新方向为上
        .elseif eax == VK_RIGHT ; 按下右箭头键
            mov snakeNewDirection, 4 ; 设置蛇的新方向为右
        .elseif eax == VK_DOWN ; 按下下箭头键
            mov snakeNewDirection, 3 ; 设置蛇的新方向为下
        .endif
    .elseif eax == WM_CLOSE || eax == WM_DESTROY
        invoke  DestroyWindow,hWinMain
        invoke PostQuitMessage, 0 ; Send quit message to exit message loop
    .else
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .endif

    xor eax, eax
    ret
_ProcWinMain endp

_WinMain proc
    local @stWndClass: WNDCLASSEX
    local @stMsg: MSG

    invoke GetModuleHandle, NULL
    mov hInstance, eax

    invoke RtlZeroMemory, addr @stWndClass, sizeof WNDCLASSEX
    invoke LoadCursor, 0, IDC_ARROW
    mov @stWndClass.hCursor, eax
    push hInstance
    pop @stWndClass.hInstance
    mov @stWndClass.cbSize, sizeof WNDCLASSEX
    mov @stWndClass.style, CS_HREDRAW or CS_VREDRAW
    mov @stWndClass.lpfnWndProc, offset _ProcWinMain
    mov @stWndClass.hbrBackground, COLOR_WINDOW + 1
    mov @stWndClass.lpszClassName, offset szClassName
    invoke RegisterClassEx, addr @stWndClass

    invoke CreateWindowEx, WS_EX_CLIENTEDGE,
        offset szClassName, offset szCaptionMain,
        WS_OVERLAPPEDWINDOW,
        500, 100, 625, 650,
        NULL, NULL, hInstance, NULL
    mov hWinMain, eax

    invoke ShowWindow, hWinMain, SW_SHOWNORMAL
    invoke UpdateWindow, hWinMain


     ; 创建定时器
    invoke SetTimer, hWinMain, TIMER_ID, TIMER_INTERVAL, NULL

    ; Message loop
    .while TRUE
        invoke GetMessage, addr @stMsg, NULL, 0, 0
        .break .if eax == 0
        invoke TranslateMessage, addr @stMsg
        invoke DispatchMessage, addr @stMsg
    .endw
    ret
_WinMain endp

start:
    
    call _WinMain
    invoke ExitProcess, NULL
end start