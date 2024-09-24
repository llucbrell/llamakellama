# vim-llamakellama

### A Vim Plugin for AI Model Interaction

This Vim plugin allows users to interact with local AI language models such as lmstudio and Ollama directly from Vim. You can send prompts and receive responses seamlessly within the Vim interface. The plugin is entirely written in Vimscript.

## Plugin Commands

### 1. :Llama <prompt>
This command sends a prompt to the configured AI API and displays the complete response where the cursor is placed. It uses streaming to progressively display the response, line by line, as it is generated.
The stream is non-blocking, so you can continue typing while the model writes the response.

**Usage**:  
`:Llama "Explain the theory of relativity"`  
`:Llama "Write an example of an HTML page"`

### 2. :Kellama
This command is designed for visual mode. It allows you to send selected text as a prompt to the API and replaces the selected text with the response.

## API Compatibility

This plugin is compatible with both lmstudio and Ollama APIs, which run locally. You can configure which API to use by setting the `g:local_ai_system` variable in your `.vimrc`.

**Example**:  
`let g:local_ai_system = "ollama"`  
or  
`let g:local_ai_system = "lmstudio"`

## Configuration in .vimrc

If you want more customization, you can use your `.vimrc`. You can define the API endpoint, model, and system prompt. The plugin will use default values if these are not defined.

**Example**:  
`let g:ai_endpoint = 'http://localhost:11434/v1/chat/completions'`  
`let g:ai_model = 'llama2'`  
`let g:ai_system_prompt = 'You are a helpful assistant.'`

- **g:ai_endpoint**: Defines the API URL for the AI model (default: `http://localhost:11434/v1/chat/completions` for Ollama).
- **g:ai_model**: Specifies the model to be used (default: `llama2` for Ollama, `lmstudio-community/gemma-2-2b-it-GGUF` for lmstudio).
- **g:ai_system_prompt**: Sets the system prompt that will guide the AI's behavior (default: `You are a helpful assistant.`).

If these variables are not set, the plugin will use the default values suitable for Ollama or lmstudio.

## Example Configuration for lmstudio

`let g:ai_endpoint = 'http://localhost:1234/v1/chat/completions'`  
`let g:ai_model = 'lmstudio-community/gemma-2-2b-it-GGUF'`  
`let g:ai_system_prompt = 'Please answer the user queries concisely.'`

## How to Use the Plugin

Once you have set up the plugin and configured the `.vimrc`, you can start interacting with the AI models directly from Vim using the provided commands:

1. To send a regular prompt and get a full response, use `:Llama`.
2. In visual mode, you can select text and use `:Kellama` to send it as a prompt and replace it with the AI-generated response.

---

# vim-llamakellama

### Un plugin de Vim para interactuar con modelos de IA

Este plugin de Vim permite a los usuarios interactuar con modelos de lenguaje de IA locales, como lmstudio y Ollama, directamente desde Vim. Puedes enviar solicitudes y recibir respuestas de manera fluida dentro de la interfaz de Vim. El plugin está completamente escrito en Vimscript.

## Comandos del Plugin

### 1. :Lllama <prompt>
Este comando envía un mensaje al API de IA configurado y muestra la respuesta completa donde está ubicado el cursor. Utiliza un sistema de transmisión (streaming) para mostrar la respuesta progresivamente, línea por línea, a medida que se genera.
El stream no bloquea el flujo, por lo que puedes seguir escribiendo mientras el modelo genera la respuesta.

**Uso**:  
`:Llama "Explica la teoría de la relatividad"`  
`:Llama "Escribe un ejemplo de una página HTML"`

### 2. :Kellama
Este comando está diseñado para el modo visual. Permite enviar el texto seleccionado como mensaje al API y reemplazar el texto seleccionado con la respuesta generada.

## Compatibilidad con APIs

Este plugin es compatible tanto con las APIs de lmstudio como de Ollama, las cuales funcionan localmente. Puedes configurar qué API usar configurando la variable `g:local_ai_system` en tu `.vimrc`.

**Ejemplo**:  
`let g:local_ai_system = "ollama"`  
o  
`let g:local_ai_system = "lmstudio"`

## Configuración en .vimrc

Si deseas más personalización, puedes usar tu archivo `.vimrc`. Puedes definir el endpoint de la API, el modelo y el mensaje del sistema. El plugin utilizará valores predeterminados si no se definen.

**Ejemplo**:  
`let g:ai_endpoint = 'http://localhost:11434/v1/chat/completions'`  
`let g:ai_model = 'llama2'`  
`let g:ai_system_prompt = 'Eres un asistente útil.'`

- **g:ai_endpoint**: Define la URL de la API para el modelo de IA (por defecto: `http://localhost:11434/v1/chat/completions` para Ollama).
- **g:ai_model**: Especifica el modelo a utilizar (por defecto: `llama2` para Ollama, `lmstudio-community/gemma-2-2b-it-GGUF` para lmstudio).
- **g:ai_system_prompt**: Establece el mensaje del sistema que guiará el comportamiento de la IA (por defecto: `Eres un asistente útil.`).

Si no se definen estas variables, el plugin utilizará los valores predeterminados adecuados para Ollama o lmstudio.

## Ejemplo de configuración para lmstudio

`let g:ai_endpoint = 'http://localhost:1234/v1/chat/completions'`  
`let g:ai_model = 'lmstudio-community/gemma-2-2b-it-GGUF'`  
`let g:ai_system_prompt = 'Por favor, responde concisamente a las consultas del usuario.'`

## Cómo usar el Plugin

Una vez que hayas configurado el plugin y el archivo `.vimrc`, puedes comenzar a interactuar con los modelos de IA directamente desde Vim usando los comandos proporcionados:

1. Para enviar un mensaje normal y obtener una respuesta completa, usa `:Llama`.
2. En modo visual, puedes seleccionar texto y usar `:Kellama` para enviarlo como mensaje y reemplazarlo con la respuesta generada por la IA.


