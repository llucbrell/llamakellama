function! SendPrompt(prompt)
" Guardar el tamaño de la ventana antes de ejecutar el comando
  let l:old_lines = &lines
  let l:old_columns = &columns
  
   " Guardar el estado de la ventana
  let l:old_view = winsaveview()

  " Ejecutar el comando curl para lmstudio
  let l:cmd = "curl -s http://localhost:1234/v1/chat/completions -H 'Content-Type: application/json' -d '{\"model\": \"lmstudio-community/gemma-2-2b-it-GGUF\", \"messages\": [{\"role\": \"system\", \"content\": \"Always answer in rhymes.\"}, {\"role\": \"user\", \"content\": \"" . substitute(a:prompt, '"', '\\"', 'g') . "\"}], \"temperature\": 0.7, \"max_tokens\": -1, \"stream\": false}'"

  " Ejecutar curl y procesar la salida
  let l:output = system(l:cmd)
  let l:parsed = json_decode(l:output)

  if has_key(l:parsed, 'choices') && len(l:parsed.choices) > 0
    let l:content = l:parsed.choices[0].message.content
  else
    echo "Error: No se encontró el campo 'content' en la respuesta."
    return
  endif

  let l:formatted_content = substitute(l:content, '\\n', "\n", 'g')
  let l:lines = split(l:formatted_content, "\n")
  call ShowOutput(l:lines)
  
  " Restaurar el tamaño y estado de la ventana
  let &lines = l:old_lines
  let &columns = l:old_columns
  call winrestview(l:old_view)
endfunction

function! ShowOutput(lines)
  " Insertar cada línea en la posición actual en el archivo abierto
  call append(line('.'), a:lines)
endfunction

function! VisualSendPrompt(line1, line2, prompt)
" Guardar el tamaño de la ventana antes de ejecutar el comando
  let l:old_lines = &lines
  let l:old_columns = &columns
  
   " Guardar el estado de la ventana
  let l:old_view = winsaveview()
  
  " Obtener las líneas seleccionadas desde line1 hasta line2
  let l:selection = getline(a:line1, a:line2)

  " Si es una selección de una sola línea
  if a:line1 == a:line2
    let l:selected_text = l:selection[0]
  else
    " Unir todas las líneas seleccionadas en un solo bloque de texto
    let l:selected_text = join(l:selection, "\n")
  endif


  " Concatenar el argumento del prompt con el texto seleccionado
  let l:final_prompt = a:prompt . "\n" . l:selected_text


 
 " Convertir el texto del prompt a UTF-8
  let l:final_prompt = iconv(l:final_prompt, &encoding, 'utf-8')


  " Aquí puedes continuar con el envío a la API, por ejemplo con curl:
  let l:escaped_prompt = substitute(l:final_prompt, '\n', '\\n', 'g')

  " Construir el objeto JSON como un diccionario de Vim
  let l:body_dict = {
        \ 'model': 'lmstudio-community/gemma-2-2b-it-GGUF',
        \ 'messages': [
        \   {'role': 'system', 'content': 'Obey literally the orders the user gives you.'},
        \   {'role': 'user', 'content': l:final_prompt}
        \ ],
        \ 'temperature': 0.7,
        \ 'max_tokens': -1,
        \ 'stream': v:false
        \ }

  " Codificar el cuerpo como JSON
  let l:body_json = json_encode(l:body_dict)


  " Escapar el cuerpo JSON correctamente
  let l:escaped_body = shellescape(l:body_json)


 " Convertir el texto del prompt a UTF-8
  let l:escaped_bodyt = iconv(l:escaped_body, &encoding, 'utf-8')


  " Ejecutar curl y procesar la salida
  let l:cmd = 'curl -s http://localhost:1234/v1/chat/completions -H "Content-Type: application/json; charset=utf-8" -d ' . l:escaped_body
  
  "let l:output = system(l:cmd)
  "silent! let l:output = system(l:cmd)
  "redraw!
  
  let l:output = system(l:cmd)
" Procesar el resultado de manera más controlada
"let l:processed_output = split(l:output, "\n")


  " Procesar la respuesta
  let l:parsed = json_decode(l:output)
  if type(l:parsed) != type({})
    echo "Error: La salida no es un JSON válido."
    return
  endif
  if has_key(l:parsed, 'choices') && len(l:parsed.choices) > 0 && has_key(l:parsed.choices[0], 'message')
    let l:content = l:parsed.choices[0].message.content
  else
    echo "Error: No se encontró el campo 'content' en la respuesta."
    return
  endif

  " Dividir el contenido en líneas e insertarlo en Vim
  let l:lines = split(l:content, "\n")
  execute a:line1 . "," . a:line2 . "d"
  call append(a:line1 - 1, l:lines)
  execute "normal! " . (a:line1 + len(l:lines) - 1) . "G"
  
  
   " Restaurar el tamaño y estado de la ventana
  let &lines = l:old_lines
  let &columns = l:old_columns
  call winrestview(l:old_view)
endfunction




function! SendPromptStream(prompt)
" Guardar el tamaño de la ventana antes de ejecutar el comando
  let l:old_lines = &lines
  let l:old_columns = &columns
  

  " Variables locales al script para evitar conflictos
  let s:last_processed_line = 0
  let s:current_line_content = ""
  let s:start_insert_line = getcurpos()[1]
  let s:timer_id = 0
  let s:tmpfile = tempname()
  let s:accumulated_content = ""  " Acumulador para el contenido pendiente
  " Get values from global variables or use defaults
  let l:endpoint = get(g:, 'ai_endpoint', 'http://localhost:11434/v1/chat/completions')
  let l:model = get(g:, 'ai_model', 'llama2')
  let l:system_prompt = get(g:, 'ai_system_prompt', 'You are a helpful assistant.')

  let l:old_view = winsaveview()

  " Comando curl modificado para escribir '[DONE]' al finalizar
  " let l:cmd = "curl --no-buffer -s http://localhost:1234/v1/chat/completions "
  let l:cmd = "curl --no-buffer -s " . l:endpoint . " "
  let l:cmd .= "-H 'Content-Type: application/json' "
  " let l:cmd .= "-d '{\"model\": \"lmstudio-community/gemma-2-2b-it-GGUF\", \"messages\": "
  let l:cmd .= "-d '{\"model\": \"" . l:model . "\", \"messages\": "
  let l:cmd .= "[{\"role\": \"system\", \"content\": \"" . substitute(l:system_prompt, '\"', '\\"', 'g') . "\"}, "
  " let l:cmd .= "[{\"role\": \"system\", \"content\": \"Always answer in rhymes.\"}, "
  let l:cmd .= "{\"role\": \"user\", \"content\": \"" . substitute(a:prompt, '\"', '\\"', 'g') . "\"}], "
  let l:cmd .= "\"temperature\": 0.7, \"max_tokens\": -1, \"stream\": true}' "
  let l:cmd .= "> " . s:tmpfile . " & echo '[DONE]' >> " . s:tmpfile

  " Ejecutar curl en segundo plano
  call system(l:cmd)

  " Iniciar un temporizador que se repite hasta que se detenga
  let s:timer_id = timer_start(500, function('s:ReadAndUpdateBuffer'), {'repeat': -1})

" Restaurar el tamaño y estado de la ventana
  let &lines = l:old_lines
  let &columns = l:old_columns
  call winrestview(l:old_view)
endfunction

function! s:ReadAndUpdateBuffer(timer)
  " Verificar si el archivo temporal existe
  if !filereadable(s:tmpfile)
    " Detener el temporizador si el archivo no existe
    call timer_stop(a:timer)
    return
  endif

  " Leer el archivo temporal
  let l:lines = readfile(s:tmpfile)

  " Procesar solo las nuevas líneas
  if s:last_processed_line >= len(l:lines)
    return
  endif

  let l:new_lines = l:lines[s:last_processed_line:]

  " Actualizar el contador de la última línea procesada
  let s:last_processed_line = len(l:lines)

  " Procesar cada línea nueva
  for line in l:new_lines
    " Eliminar 'data: ' del inicio de cada línea si está presente
    if line =~ '^data: '
      let line = substitute(line, '^data: ', '', '')
    endif

    " Verificar si el streaming ha terminado
    if line == '[DONE]'
      " Detener el temporizador
      call timer_stop(a:timer)
      " Procesar cualquier contenido restante
      if s:current_line_content != ''
        call s:ProcessContent(s:current_line_content)
        let s:current_line_content = ''
      endif
      " Procesar cualquier contenido pendiente en el acumulador
      if s:accumulated_content != ''
        call append(s:start_insert_line - 1, s:accumulated_content)
        let s:start_insert_line += 1
        let s:accumulated_content = ''
      endif
      " Eliminar el archivo temporal
      call delete(s:tmpfile)
      return
    endif

    " Acumular la línea actual
    let s:current_line_content .= line

    " Intentar decodificar el JSON acumulado
    try
      let json_data = json_decode(s:current_line_content)
      " Reiniciar el acumulador de JSON
      let s:current_line_content = ''
      " Verificar que json_data es un diccionario
      if type(json_data) == type({})
        " Verificar que tiene la clave 'choices' y que es una lista
        if has_key(json_data, 'choices') && type(json_data.choices) == type([]) && !empty(json_data.choices)
          " Verificar que el primer elemento tiene 'delta'
          if has_key(json_data.choices[0], 'delta')
            " Verificar que 'delta' tiene 'content'
            if has_key(json_data.choices[0].delta, 'content')
              let content = json_data.choices[0].delta.content
              " Procesar el contenido recibido
              call s:ProcessContent(content)
            endif
          endif
        else
          echom 'Respuesta inesperada: ' . string(json_data)
        endif
      else
        echom 'json_data no es un diccionario: ' . string(json_data)
      endif
    catch
      " Si json_decode falla, esperar más datos
      " No hacer nada aquí
    endtry
  endfor
endfunction

function! s:ProcessContent(content)
  " Añadir el contenido al acumulador
  let s:accumulated_content .= a:content

  " Reemplazar saltos de línea escapados por saltos de línea reales
  let s:accumulated_content = substitute(s:accumulated_content, '\\n', "\n", 'g')

  " Procesar el acumulador para extraer líneas completas
  while match(s:accumulated_content, '\n') >= 0
    " Encontrar el índice del primer salto de línea
    let l:newline_idx = match(s:accumulated_content, '\n')

    " Extraer la línea completa
    let l:line = strpart(s:accumulated_content, 0, l:newline_idx)

    " Insertar la línea en el buffer
    call append(s:start_insert_line - 1, l:line)
    let s:start_insert_line += 1

    " Eliminar la línea procesada del acumulador
    let s:accumulated_content = strpart(s:accumulated_content, l:newline_idx + 1)
  endwhile
  
  
endfunction




function! VisualSendPromptStream(line1, line2, prompt)
  " Variables locales al script para evitar conflictos
  let s:last_processed_line = 0
  let s:current_line_content = ""
  let s:start_insert_line = a:line1
  let s:timer_id = 0
  let s:tmpfile = tempname()
  let s:accumulated_content = ""  " Acumulador para el contenido pendiente

  " Guardar el estado de la ventana
  let l:old_view = winsaveview()

  " Obtener las líneas seleccionadas desde line1 hasta line2
  let l:selection = getline(a:line1, a:line2)

  " Unir todas las líneas seleccionadas en un solo bloque de texto
  let l:selected_text = join(l:selection, "\n")

  " Concatenar el argumento del prompt con el texto seleccionado
  let l:final_prompt = a:prompt . "\n" . l:selected_text

   " Get values from global variables or use defaults
  let l:endpoint = get(g:, 'ai_endpoint', 'http://localhost:11434/v1/chat/completions')
  let l:model = get(g:, 'ai_model', 'llama2')
  let l:system_prompt = get(g:, 'ai_system_prompt', 'You are a helpful assistant.')


  " Construir el objeto JSON como un diccionario de Vim
  let l:body_dict = {
        \ 'model': l:model,
        \ 'messages': [
        \   {'role': 'system', 'content':l:system_prompt},
        \   {'role': 'user', 'content': l:final_prompt}
        \ ],
        \ 'temperature': 0.7,
        \ 'max_tokens': -1,
        \ 'stream': v:true
        \ }

  " Codificar el cuerpo como JSON
  let l:body_json = json_encode(l:body_dict)

  " Escapar el cuerpo JSON para el shell
  let l:escaped_body = shellescape(l:body_json)

  " Construir el comando curl
  " let l:cmd = 'curl --no-buffer -s http://localhost:1234/v1/chat/completions '
  let l:cmd = 'curl --no-buffer -s ' . l:endpoint . ' '
  let l:cmd .= '-H "Content-Type: application/json" '
  let l:cmd .= '-d ' . l:escaped_body . ' '
  let l:cmd .= '> ' . s:tmpfile . ' & echo "[DONE]" >> ' . s:tmpfile


  " Ejecutar curl en segundo plano
  call system(l:cmd)

  " Eliminar las líneas seleccionadas para preparar el espacio
  execute a:line1 . "," . a:line2 . "d"

  " Iniciar un temporizador que se repite hasta que se detenga
  let s:timer_id = timer_start(500, function('s:ReadAndUpdateBufferVisual'), {'repeat': -1})

  call winrestview(l:old_view)
endfunction

function! s:ReadAndUpdateBufferVisual(timer)
  " Verificar si el archivo temporal existe
  if !filereadable(s:tmpfile)
    " Detener el temporizador si el archivo no existe
    call timer_stop(a:timer)
    return
  endif

  " Leer el archivo temporal
  let l:lines = readfile(s:tmpfile)

  " Procesar solo las nuevas líneas
  if s:last_processed_line >= len(l:lines)
    return
  endif

  let l:new_lines = l:lines[s:last_processed_line:]

  " Actualizar el contador de la última línea procesada
  let s:last_processed_line = len(l:lines)

  " Procesar cada línea nueva
  for line in l:new_lines
    " Eliminar 'data: ' del inicio de cada línea si está presente
    if line =~ '^data: '
      let line = substitute(line, '^data: ', '', '')
    endif

    " Verificar si el streaming ha terminado
    if line == '[DONE]'
      " Detener el temporizador
      call timer_stop(a:timer)
      " Procesar cualquier contenido restante
      if s:current_line_content != ''
        call s:ProcessContentVisual(s:current_line_content)
        let s:current_line_content = ''
      endif
      " Procesar cualquier contenido pendiente en el acumulador
      if s:accumulated_content != ''
        call append(s:start_insert_line - 1, s:accumulated_content)
        let s:start_insert_line += 1
        let s:accumulated_content = ''
      endif
      " Eliminar el archivo temporal
      call delete(s:tmpfile)
      return
    endif

    " Acumular la línea actual
    let s:current_line_content .= line

    " Intentar decodificar el JSON acumulado
    try
      let json_data = json_decode(s:current_line_content)
      " Reiniciar el acumulador de JSON
      let s:current_line_content = ''
      " Verificar que json_data es un diccionario
      if type(json_data) == type({})
        " Verificar que tiene la clave 'choices' y que es una lista
        if has_key(json_data, 'choices') && type(json_data.choices) == type([]) && !empty(json_data.choices)
          " Verificar que el primer elemento tiene 'delta'
          if has_key(json_data.choices[0], 'delta')
            " Verificar que 'delta' tiene 'content'
            if has_key(json_data.choices[0].delta, 'content')
              let content = json_data.choices[0].delta.content
              " Procesar el contenido recibido
              call s:ProcessContentVisual(content)
            endif
          endif
        else
          echom 'Respuesta inesperada: ' . string(json_data)
        endif
      else
        echom 'json_data no es un diccionario: ' . string(json_data)
      endif
    catch
      " Si json_decode falla, esperar más datos
      " No hacer nada aquí
    endtry
  endfor
endfunction

function! s:ProcessContentVisual(content)
  " Añadir el contenido al acumulador
  let s:accumulated_content .= a:content

  " Reemplazar saltos de línea escapados por saltos de línea reales
  let s:accumulated_content = substitute(s:accumulated_content, '\\n', "\n", 'g')

  " Procesar el acumulador para extraer líneas completas
  while match(s:accumulated_content, '\n') >= 0
    " Encontrar el índice del primer salto de línea
    let l:newline_idx = match(s:accumulated_content, '\n')

    " Extraer la línea completa
    let l:line = strpart(s:accumulated_content, 0, l:newline_idx)

    " Insertar la línea en el buffer
    call append(s:start_insert_line - 1, l:line)
    let s:start_insert_line += 1

    " Eliminar la línea procesada del acumulador
    let s:accumulated_content = strpart(s:accumulated_content, l:newline_idx + 1)
  endwhile
endfunction
