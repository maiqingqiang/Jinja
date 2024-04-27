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
    ]

    func testDefaultTemplates() throws {
        for test in defaultTemplates {
            let template = try Template(test.chatTemplate)
            let result = try template.render(test.data)

            XCTAssertEqual(result.debugDescription, test.target.debugDescription)
        }
    }
}
