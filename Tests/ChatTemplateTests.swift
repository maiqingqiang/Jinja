//
//  ChatTemplateTests.swift
//
//
//  Created by John Mai on 2024/3/24.
//

import XCTest

@testable import Jinja

let messages: [[String: String]] = [
    [
        "role": "user",
        "content": "Hello, how are you?",
    ],
    [
        "role": "assistant",
        "content": "I'm doing great. How can I help you today?",
    ],
    [
        "role": "user",
        "content": "I'd like to show off how chat templating works!",
    ],
]

let messagesWithSystem: [[String: String]] =
    [
        [
            "role": "system",
            "content": "You are a friendly chatbot who always responds in the style of a pirate",
        ]
    ] + messages

final class ChatTemplateTests: XCTestCase {
    struct Test {
        let chatTemplate: String
        let data: [String: Any]
        let target: String
    }

    let defaultTemplates: [Test] = [
        Test(
            chatTemplate:
                "{% for message in messages %}{{'<|im_start|>' + message['role'] + '\n' + message['content'] + '<|im_end|>' + '\n'}}{% endfor %}{% if add_generation_prompt %}{{ '<|im_start|>assistant\n' }}{% endif %}",
            data: [
                "messages": messages,
                "add_generation_prompt": false,
            ],
            target:
                "<|im_start|>user\nHello, how are you?<|im_end|>\n<|im_start|>assistant\nI'm doing great. How can I help you today?<|im_end|>\n<|im_start|>user\nI'd like to show off how chat templating works!<|im_end|>\n"
        ),
        // facebook/blenderbot-400M-distill
        Test(
            chatTemplate:
                "{% for message in messages %}{% if message['role'] == 'user' %}{{ ' ' }}{% endif %}{{ message['content'] }}{% if not loop.last %}{{ '  ' }}{% endif %}{% endfor %}{{ eos_token }}",
            data: [
                "messages": messages,
                "eos_token": "</s>",
            ],
            target:
                " Hello, how are you?  I'm doing great. How can I help you today?   I'd like to show off how chat templating works!</s>"
        ),
        // facebook/blenderbot_small-90M
        Test(
            chatTemplate:
                "{% for message in messages %}{% if message['role'] == 'user' %}{{ ' ' }}{% endif %}{{ message['content'] }}{% if not loop.last %}{{ '  ' }}{% endif %}{% endfor %}{{ eos_token }}",
            data: [
                "messages": messages,
                "eos_token": "</s>",
            ],
            target:
                " Hello, how are you?  I'm doing great. How can I help you today?   I'd like to show off how chat templating works!</s>"
        ),
        // bigscience/bloom
        Test(
            chatTemplate: "{% for message in messages %}{{ message.content }}{{ eos_token }}{% endfor %}",
            data: [
                "messages": messages,
                "eos_token": "</s>",
            ],
            target:
                "Hello, how are you?</s>I'm doing great. How can I help you today?</s>I'd like to show off how chat templating works!</s>"
        ),
        // EleutherAI/gpt-neox-20b
        Test(
            chatTemplate: "{% for message in messages %}{{ message.content }}{{ eos_token }}{% endfor %}",
            data: [
                "messages": messages,
                "eos_token": "<|endoftext|>",
            ],
            target:
                "Hello, how are you?<|endoftext|>I'm doing great. How can I help you today?<|endoftext|>I'd like to show off how chat templating works!<|endoftext|>"
        ),
        // gpt2
        Test(
            chatTemplate: "{% for message in messages %}{{ message.content }}{{ eos_token }}{% endfor %}",
            data: [
                "messages": messages,
                "eos_token": "<|endoftext|>",
            ],
            target:
                "Hello, how are you?<|endoftext|>I'm doing great. How can I help you today?<|endoftext|>I'd like to show off how chat templating works!<|endoftext|>"
        ),
        // hf-internal-testing/llama-tokenizer
        Test(
            chatTemplate:
                "{% if messages[0]['role'] == 'system' %}{% set loop_messages = messages[1:] %}{% set system_message = messages[0]['content'] %}{% elif USE_DEFAULT_PROMPT == true and not '<<SYS>>' in messages[0]['content'] %}{% set loop_messages = messages %}{% set system_message = 'DEFAULT_SYSTEM_MESSAGE' %}{% else %}{% set loop_messages = messages %}{% set system_message = false %}{% endif %}{% for message in loop_messages %}{% if (message['role'] == 'user') != (loop.index0 % 2 == 0) %}{{ raise_exception('Conversation roles must alternate user/assistant/user/assistant/...') }}{% endif %}{% if loop.index0 == 0 and system_message != false %}{% set content = '<<SYS>>\\n' + system_message + '\\n<</SYS>>\\n\\n' + message['content'] %}{% else %}{% set content = message['content'] %}{% endif %}{% if message['role'] == 'user' %}{{ bos_token + '[INST] ' + content.strip() + ' [/INST]' }}{% elif message['role'] == 'system' %}{{ '<<SYS>>\\n' + content.strip() + '\\n<</SYS>>\\n\\n' }}{% elif message['role'] == 'assistant' %}{{ ' ' + content.strip() + ' ' + eos_token }}{% endif %}{% endfor %}",
            data: [
                "messages": messagesWithSystem,
                "bos_token": "<s>",
                "eos_token": "</s>",
                "USE_DEFAULT_PROMPT": true,
            ],
            target:
                "<s>[INST] <<SYS>>\nYou are a friendly chatbot who always responds in the style of a pirate\n<</SYS>>\n\nHello, how are you? [/INST] I'm doing great. How can I help you today? </s><s>[INST] I'd like to show off how chat templating works! [/INST]"
        ),
        // hf-internal-testing/llama-tokenizer
        Test(
            chatTemplate:
                "{% if messages[0]['role'] == 'system' %}{% set loop_messages = messages[1:] %}{% set system_message = messages[0]['content'] %}{% elif USE_DEFAULT_PROMPT == true and not '<<SYS>>' in messages[0]['content'] %}{% set loop_messages = messages %}{% set system_message = 'DEFAULT_SYSTEM_MESSAGE' %}{% else %}{% set loop_messages = messages %}{% set system_message = false %}{% endif %}{% for message in loop_messages %}{% if (message['role'] == 'user') != (loop.index0 % 2 == 0) %}{{ raise_exception('Conversation roles must alternate user/assistant/user/assistant/...') }}{% endif %}{% if loop.index0 == 0 and system_message != false %}{% set content = '<<SYS>>\\n' + system_message + '\\n<</SYS>>\\n\\n' + message['content'] %}{% else %}{% set content = message['content'] %}{% endif %}{% if message['role'] == 'user' %}{{ bos_token + '[INST] ' + content.strip() + ' [/INST]' }}{% elif message['role'] == 'system' %}{{ '<<SYS>>\\n' + content.strip() + '\\n<</SYS>>\\n\\n' }}{% elif message['role'] == 'assistant' %}{{ ' ' + content.strip() + ' ' + eos_token }}{% endif %}{% endfor %}",
            data: [
                "messages": messages,
                "bos_token": "<s>",
                "eos_token": "</s>",
                "USE_DEFAULT_PROMPT": true,
            ],
            target:
                "<s>[INST] <<SYS>>\nDEFAULT_SYSTEM_MESSAGE\n<</SYS>>\n\nHello, how are you? [/INST] I'm doing great. How can I help you today? </s><s>[INST] I'd like to show off how chat templating works! [/INST]"
        ),
        // hf-internal-testing/llama-tokenizer
        Test(
            chatTemplate:
                "{% if messages[0]['role'] == 'system' %}{% set loop_messages = messages[1:] %}{% set system_message = messages[0]['content'] %}{% elif USE_DEFAULT_PROMPT == true and not '<<SYS>>' in messages[0]['content'] %}{% set loop_messages = messages %}{% set system_message = 'DEFAULT_SYSTEM_MESSAGE' %}{% else %}{% set loop_messages = messages %}{% set system_message = false %}{% endif %}{% for message in loop_messages %}{% if (message['role'] == 'user') != (loop.index0 % 2 == 0) %}{{ raise_exception('Conversation roles must alternate user/assistant/user/assistant/...') }}{% endif %}{% if loop.index0 == 0 and system_message != false %}{% set content = '<<SYS>>\\n' + system_message + '\\n<</SYS>>\\n\\n' + message['content'] %}{% else %}{% set content = message['content'] %}{% endif %}{% if message['role'] == 'user' %}{{ bos_token + '[INST] ' + content.strip() + ' [/INST]' }}{% elif message['role'] == 'system' %}{{ '<<SYS>>\\n' + content.strip() + '\\n<</SYS>>\\n\\n' }}{% elif message['role'] == 'assistant' %}{{ ' ' + content.strip() + ' ' + eos_token }}{% endif %}{% endfor %}",
            data: [
                "messages": [
                    [
                        "role": "user",
                        "content": "<<SYS>>\nYou are a helpful assistant\n<</SYS>> Hello, how are you?",
                    ],
                    [
                        "role": "assistant",
                        "content": "I'm doing great. How can I help you today?",
                    ],
                    [
                        "role": "user",
                        "content": "I'd like to show off how chat templating works!",
                    ],
                ],
                "bos_token": "<s>",
                "eos_token": "</s>",
                "USE_DEFAULT_PROMPT": true,
            ],
            target:
                "<s>[INST] <<SYS>>\nYou are a helpful assistant\n<</SYS>> Hello, how are you? [/INST] I'm doing great. How can I help you today? </s><s>[INST] I'd like to show off how chat templating works! [/INST]"
        ),
        // openai/whisper-large-v3
        Test(
            chatTemplate: "{% for message in messages %}{{ message.content }}{{ eos_token }}{% endfor %}",
            data: [
                "messages": messages,
                "eos_token": "<|endoftext|>",
            ],
            target:
                "Hello, how are you?<|endoftext|>I'm doing great. How can I help you today?<|endoftext|>I'd like to show off how chat templating works!<|endoftext|>"
        ),
        // Qwen/Qwen1.5-1.8B-Chat
        Test(
            chatTemplate:
                "{% for message in messages %}{% if loop.first and messages[0]['role'] != 'system' %}{{ '<|im_start|>system\nYou are a helpful assistant<|im_end|>\n' }}{% endif %}{{'<|im_start|>' + message['role'] + '\n' + message['content']}}{% if (loop.last and add_generation_prompt) or not loop.last %}{{ '<|im_end|>' + '\n'}}{% endif %}{% endfor %}{% if add_generation_prompt and messages[-1]['role'] != 'assistant' %}{{ '<|im_start|>assistant\n' }}{% endif %}",
            data: [
                "messages": messages,
                "add_generation_prompt": true,
            ],
            target:
                "<|im_start|>system\nYou are a helpful assistant<|im_end|>\n<|im_start|>user\nHello, how are you?<|im_end|>\n<|im_start|>assistant\nI\'m doing great. How can I help you today?<|im_end|>\n<|im_start|>user\nI\'d like to show off how chat templating works!<|im_end|>\n<|im_start|>assistant\n"
        ),
        // Qwen/Qwen1.5-1.8B-Chat
        Test(
            chatTemplate:
                "{% for message in messages %}{% if loop.first and messages[0]['role'] != 'system' %}{{ '<|im_start|>system\nYou are a helpful assistant<|im_end|>\n' }}{% endif %}{{'<|im_start|>' + message['role'] + '\n' + message['content']}}{% if (loop.last and add_generation_prompt) or not loop.last %}{{ '<|im_end|>' + '\n'}}{% endif %}{% endfor %}{% if add_generation_prompt and messages[-1]['role'] != 'assistant' %}{{ '<|im_start|>assistant\n' }}{% endif %}",
            data: [
                "messages": messagesWithSystem,
                "add_generation_prompt": true,
            ],
            target:
                "<|im_start|>system\nYou are a friendly chatbot who always responds in the style of a pirate<|im_end|>\n<|im_start|>user\nHello, how are you?<|im_end|>\n<|im_start|>assistant\nI\'m doing great. How can I help you today?<|im_end|>\n<|im_start|>user\nI\'d like to show off how chat templating works!<|im_end|>\n<|im_start|>assistant\n"
        ),
        // Qwen/Qwen1.5-1.8B-Chat
        Test(
            chatTemplate:
                "{% for message in messages %}{% if loop.first and messages[0]['role'] != 'system' %}{{ '<|im_start|>system\nYou are a helpful assistant<|im_end|>\n' }}{% endif %}{{'<|im_start|>' + message['role'] + '\n' + message['content']}}{% if (loop.last and add_generation_prompt) or not loop.last %}{{ '<|im_end|>' + '\n'}}{% endif %}{% endfor %}{% if add_generation_prompt and messages[-1]['role'] != 'assistant' %}{{ '<|im_start|>assistant\n' }}{% endif %}",
            data: [
                "messages": messagesWithSystem
            ],
            target:
                "<|im_start|>system\nYou are a friendly chatbot who always responds in the style of a pirate<|im_end|>\n<|im_start|>user\nHello, how are you?<|im_end|>\n<|im_start|>assistant\nI\'m doing great. How can I help you today?<|im_end|>\n<|im_start|>user\nI\'d like to show off how chat templating works!"
        ),
        // THUDM/chatglm3-6b
        Test(
            chatTemplate:
                "{% for message in messages %}{% if loop.first %}[gMASK]sop<|{{ message['role'] }}|>\n {{ message['content'] }}{% else %}<|{{ message['role'] }}|>\n {{ message['content'] }}{% endif %}{% endfor %}{% if add_generation_prompt %}<|assistant|>{% endif %}",
            data: [
                "messages": messagesWithSystem
            ],
            target:
                "[gMASK]sop<|system|>\n You are a friendly chatbot who always responds in the style of a pirate<|user|>\n Hello, how are you?<|assistant|>\n I\'m doing great. How can I help you today?<|user|>\n I\'d like to show off how chat templating works!"
        ),
        // google/gemma-2b-it
        Test(
            chatTemplate:
                "{{ bos_token }}{% if messages[0]['role'] == 'system' %}{{ raise_exception('System role not supported') }}{% endif %}{% for message in messages %}{% if (message['role'] == 'user') != (loop.index0 % 2 == 0) %}{{ raise_exception('Conversation roles must alternate user/assistant/user/assistant/...') }}{% endif %}{% if (message['role'] == 'assistant') %}{% set role = 'model' %}{% else %}{% set role = message['role'] %}{% endif %}{{ '<start_of_turn>' + role + '\n' + message['content'] | trim + '<end_of_turn>\n' }}{% endfor %}{% if add_generation_prompt %}{{'<start_of_turn>model\n'}}{% endif %}",
            data: [
                "messages": messages
            ],
            target:
                "<start_of_turn>user\nHello, how are you?<end_of_turn>\n<start_of_turn>model\nI\'m doing great. How can I help you today?<end_of_turn>\n<start_of_turn>user\nI\'d like to show off how chat templating works!<end_of_turn>\n"
        ),
        // Qwen/Qwen2.5-0.5B-Instruct
        Test(
            chatTemplate:
                "{%- if tools %}\n    {{- '<|im_start|>system\\n' }}\n    {%- if messages[0]['role'] == 'system' %}\n        {{- messages[0]['content'] }}\n    {%- else %}\n        {{- 'You are Qwen, created by Alibaba Cloud. You are a helpful assistant.' }}\n    {%- endif %}\n    {{- \"\\n\\n# Tools\\n\\nYou may call one or more functions to assist with the user query.\\n\\nYou are provided with function signatures within <tools></tools> XML tags:\\n<tools>\" }}\n    {%- for tool in tools %}\n        {{- \"\\n\" }}\n        {{- tool | tojson }}\n    {%- endfor %}\n    {{- \"\\n</tools>\\n\\nFor each function call, return a json object with function name and arguments within <tool_call></tool_call> XML tags:\\n<tool_call>\\n{\\\"name\\\": <function-name>, \\\"arguments\\\": <args-json-object>}\\n</tool_call><|im_end|>\\n\" }}\n{%- else %}\n    {%- if messages[0]['role'] == 'system' %}\n        {{- '<|im_start|>system\\n' + messages[0]['content'] + '<|im_end|>\\n' }}\n    {%- else %}\n        {{- '<|im_start|>system\\nYou are Qwen, created by Alibaba Cloud. You are a helpful assistant.<|im_end|>\\n' }}\n    {%- endif %}\n{%- endif %}\n{%- for message in messages %}\n    {%- if (message.role == \"user\") or (message.role == \"system\" and not loop.first) or (message.role == \"assistant\" and not message.tool_calls) %}\n        {{- '<|im_start|>' + message.role + '\\n' + message.content + '<|im_end|>' + '\\n' }}\n    {%- elif message.role == \"assistant\" %}\n        {{- '<|im_start|>' + message.role }}\n        {%- if message.content %}\n            {{- '\\n' + message.content }}\n        {%- endif %}\n        {%- for tool_call in message.tool_calls %}\n            {%- if tool_call.function is defined %}\n                {%- set tool_call = tool_call.function %}\n            {%- endif %}\n            {{- '\\n<tool_call>\\n{\"name\": \"' }}\n            {{- tool_call.name }}\n            {{- '\", \"arguments\": ' }}\n            {{- tool_call.arguments | tojson }}\n            {{- '}\\n</tool_call>' }}\n        {%- endfor %}\n        {{- '<|im_end|>\\n' }}\n    {%- elif message.role == \"tool\" %}\n        {%- if (loop.index0 == 0) or (messages[loop.index0 - 1].role != \"tool\") %}\n            {{- '<|im_start|>user' }}\n        {%- endif %}\n        {{- '\\n<tool_response>\\n' }}\n        {{- message.content }}\n        {{- '\\n</tool_response>' }}\n        {%- if loop.last or (messages[loop.index0 + 1].role != \"tool\") %}\n            {{- '<|im_end|>\\n' }}\n        {%- endif %}\n    {%- endif %}\n{%- endfor %}\n{%- if add_generation_prompt %}\n    {{- '<|im_start|>assistant\\n' }}\n{%- endif %}\n",
            data: [
                "messages": messages
            ],
            target:
                "<|im_start|>system\nYou are Qwen, created by Alibaba Cloud. You are a helpful assistant.<|im_end|>\n<|im_start|>user\nHello, how are you?<|im_end|>\n<|im_start|>assistant\nI\'m doing great. How can I help you today?<|im_end|>\n<|im_start|>user\nI\'d like to show off how chat templating works!<|im_end|>\n"
        ),
    ]

    func testDefaultTemplates() throws {
        for test in defaultTemplates {
            let template = try Template(test.chatTemplate)
            let result = try template.render(test.data)
            XCTAssertEqual(result.debugDescription, test.target.debugDescription)
        }
    }
}
