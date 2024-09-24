if !exists("g:local_ai_system")
  echo "Error: Debes establecer la variable 'local_ai_system' en tu .vimrc (ollama o lmstudio)"
  finish
endif

" Obtener la ruta actual del archivo de plugin y usarla para cargar los archivos correctamente
let s:plugin_path = expand('<sfile>:p:h')

" Cargar el archivo correspondiente dependiendo del valor de local_ai_system
if g:local_ai_system ==# 'lmstudio'
  execute 'source ' . s:plugin_path . '/lmstudio.vim'
elseif g:local_ai_system ==# 'ollama'
  execute 'source ' . s:plugin_path . '/ollama.vim'
else
  echo "Error: Valor no reconocido para 'local_ai_system'. Usa 'ollama' o 'lmstudio'."
  finish
endif

" Comando unificado que ejecuta la función según el sistema
command! -nargs=1 Aia call SendPrompt(<q-args>)
command! -nargs=1 Llama call SendPromptStream(<q-args>)


" Comando unificado para el modo visual
" command! -range=% -nargs=? VisualPrompt <line1>,<line2>call VisualSendPrompt(<f-args>)
command! -range -nargs=1 Eia <line1> call VisualSendPrompt(<line1>, <line2>, <q-args>)
command! -range -nargs=1 Kellama <line1> call VisualSendPromptStream(<line1>, <line2>, <q-args>)

