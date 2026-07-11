{
  "$schema": "https://opencode.ai/config.json",
  "disabled_providers": [],
  "snapshot": true,
  "provider": {
    "openrouter": {
      "models": {
        "qwen/qwen3-coder:free": {
          "name": "fast-coder",
          "options": {
            "allow_fallbacks": false,
            "max_tokens": 32000
          }
        },
        "moonshotai/kimi-k2:free": {
          "name": "fast-kimi",
          "options": {
            "allow_fallbacks": false
          }
        },
        "qwen/qwen3-next-80b-a3b-instruct:free": {
          "name": "qwen3-80b",
          "options": {
            "allow_fallbacks": false
          }
        }
      }
    },
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "qwen3-coder-iq4xs-128k": {
          "name": "Qwen3-Coder 30B IQ4_XS 128K",
          "max_tokens": 131072
        },
        "qwen3-coder-iq4xs-96k": {
          "name": "Qwen3-Coder 30B IQ4_XS 96K",
          "max_tokens": 98304
        },
        "qwen3-coder-iq4xs-64k": {
          "name": "Qwen3-Coder 30B IQ4_XS 64K",
          "max_tokens": 65536
        },
        "qwen3-coder-iq4xs-48k": {
          "name": "Qwen3-Coder 30B IQ4_XS 48K",
          "max_tokens": 49152
        }
      }
    },
    "llamacpp": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama.cpp (local)",
      "options": {
        "baseURL": "http://localhost:8081/v1"
      },
      "models": {
        "qwen35-27b-iq4xs-128k": {
          "name": "Qwen3.5-27B IQ4_XS 128K",
          "max_tokens": 131072
        },
        "qwen3-coder": {
          "name": "Qwen3-Coder 30B IQ4_XS 131K",
          "max_tokens": 131072,
          "options": {
            "max_tokens": 8000
          }
        }
      }
    },
    "sglang": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "SGLang (local)",
      "options": {
        "baseURL": "http://localhost:8081/v1"
      },
      "models": {
        "gemma4-26b": {
          "name": "Gemma 4 26B-A4B Text-Only AWQ-4bit (SGLang 51K)",
          "max_tokens": 51306
        }
      }
    },
    "openai": {
      "whitelist": [
        "gpt-5.5",
        "gpt-5.5-low",
        "gpt-5.5-medium",
        "gpt-5.5-high",
        "gpt-5.5-xhigh",
        "gpt-5.5-fast",
        "gpt-5.6-luna",
        "gpt-5.6-luna-low",
        "gpt-5.6-luna-medium",
        "gpt-5.6-luna-high",
        "gpt-5.6-luna-xhigh",
        "gpt-5.6-luna-fast",
        "gpt-5.6-terra",
        "gpt-5.6-terra-low",
        "gpt-5.6-terra-medium",
        "gpt-5.6-terra-high",
        "gpt-5.6-terra-xhigh",
        "gpt-5.6-terra-fast",
        "gpt-5.6-sol",
        "gpt-5.6-sol-low",
        "gpt-5.6-sol-medium",
        "gpt-5.6-sol-high",
        "gpt-5.6-sol-xhigh",
        "gpt-5.6-sol-fast"
      ],
      "models": {
        "gpt-5.3-codex-spark": {
          "name": "GPT 5.3 Codex Spark Subscription",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "variants": {
            "low": {
              "reasoningEffort": "low",
              "reasoningSummary": "auto",
              "textVerbosity": "medium"
            },
            "medium": {
              "reasoningEffort": "medium",
              "reasoningSummary": "auto",
              "textVerbosity": "medium"
            },
            "high": {
              "reasoningEffort": "high",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium"
            },
            "xhigh": {
              "reasoningEffort": "xhigh",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium"
            },
            "fast": {
              "reasoningEffort": "high",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium",
              "serviceTier": "priority"
            }
          }
        },
        "gpt-5.4": {
          "name": "GPT 5.4 Codex Subscription",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "variants": {
            "low": {
              "reasoningEffort": "low",
              "reasoningSummary": "auto",
              "textVerbosity": "medium"
            },
            "medium": {
              "reasoningEffort": "medium",
              "reasoningSummary": "auto",
              "textVerbosity": "medium"
            },
            "high": {
              "reasoningEffort": "high",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium"
            },
            "xhigh": {
              "reasoningEffort": "xhigh",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium"
            },
            "fast": {
              "reasoningEffort": "high",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium",
              "serviceTier": "priority"
            }
          }
        },
        "gpt-5.4-mini": {
          "name": "GPT 5.4 Mini Subscription",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "variants": {
            "low": {
              "reasoningEffort": "low",
              "reasoningSummary": "auto",
              "textVerbosity": "medium"
            },
            "medium": {
              "reasoningEffort": "medium",
              "reasoningSummary": "auto",
              "textVerbosity": "medium"
            },
            "high": {
              "reasoningEffort": "high",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium"
            },
            "xhigh": {
              "reasoningEffort": "xhigh",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium"
            },
            "fast": {
              "reasoningEffort": "high",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium",
              "serviceTier": "priority"
            }
          }
        },
        "gpt-5.5": {
          "name": "GPT 5.5 Codex Subscription",
          "limit": {
            "context": 1000000,
            "output": 128000
          },
          "variants": {
            "low": {
              "reasoningEffort": "low",
              "reasoningSummary": "auto",
              "textVerbosity": "medium"
            },
            "medium": {
              "reasoningEffort": "medium",
              "reasoningSummary": "auto",
              "textVerbosity": "medium"
            },
            "high": {
              "reasoningEffort": "high",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium"
            },
            "xhigh": {
              "reasoningEffort": "xhigh",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium"
            },
            "fast": {
              "reasoningEffort": "high",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium",
              "serviceTier": "priority"
            }
          }
        },
        "gpt-5.6-luna": {
          "name": "GPT 5.6 Luna Codex Subscription",
          "limit": {
            "context": 1050000,
            "output": 128000
          },
          "variants": {
            "low": {
              "reasoningEffort": "low",
              "reasoningSummary": "auto",
              "textVerbosity": "medium"
            },
            "medium": {
              "reasoningEffort": "medium",
              "reasoningSummary": "auto",
              "textVerbosity": "medium"
            },
            "high": {
              "reasoningEffort": "high",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium"
            },
            "xhigh": {
              "reasoningEffort": "xhigh",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium"
            },
            "fast": {
              "reasoningEffort": "high",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium",
              "serviceTier": "priority"
            }
          }
        },
        "gpt-5.6-terra": {
          "name": "GPT 5.6 Terra Codex Subscription",
          "limit": {
            "context": 1050000,
            "output": 128000
          },
          "variants": {
            "low": {
              "reasoningEffort": "low",
              "reasoningSummary": "auto",
              "textVerbosity": "medium"
            },
            "medium": {
              "reasoningEffort": "medium",
              "reasoningSummary": "auto",
              "textVerbosity": "medium"
            },
            "high": {
              "reasoningEffort": "high",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium"
            },
            "xhigh": {
              "reasoningEffort": "xhigh",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium"
            },
            "fast": {
              "reasoningEffort": "high",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium",
              "serviceTier": "priority"
            }
          }
        },
        "gpt-5.6-sol": {
          "name": "GPT 5.6 Sol Codex Subscription",
          "limit": {
            "context": 1050000,
            "output": 128000
          },
          "variants": {
            "low": {
              "reasoningEffort": "low",
              "reasoningSummary": "auto",
              "textVerbosity": "medium"
            },
            "medium": {
              "reasoningEffort": "medium",
              "reasoningSummary": "auto",
              "textVerbosity": "medium"
            },
            "high": {
              "reasoningEffort": "high",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium"
            },
            "xhigh": {
              "reasoningEffort": "xhigh",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium"
            },
            "fast": {
              "reasoningEffort": "high",
              "reasoningSummary": "detailed",
              "textVerbosity": "medium",
              "serviceTier": "priority"
            }
          }
        }
      }
    }
  },
  "agent": {
    "relay-sol": {
      "model": "openai/gpt-5.6-sol",
      "variant": "xhigh",
      "mode": "subagent",
      "description": "Use for GPT-5.6 relay coordination, architecture, ambiguity, hard diagnosis, and high-risk review."
    },
    "relay-terra": {
      "model": "openai/gpt-5.6-terra",
      "variant": "high",
      "mode": "subagent",
      "description": "Use for GPT-5.6 relay implementation, tests, refactors, bounded debugging, and code review."
    },
    "relay-luna": {
      "model": "openai/gpt-5.6-luna",
      "variant": "medium",
      "mode": "subagent",
      "description": "Use for GPT-5.6 relay reconnaissance, deterministic edits, formatting, focused checks, release mechanics, and monitoring."
    }
  },
  "permission": {
    "bash": "allow",
    "edit": "allow",
    "read": "allow",
    "grep": "allow",
    "glob": "allow",
    "list": "allow",
    "patch": "allow",
    "skill": "allow",
    "todoread": "allow",
    "todowrite": "allow",
    "question": "allow",
    "external_directory": "allow"
  },
  "mcp": {
    "filesystem": {
      "type": "local",
      "command": [
        "npx",
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "${HOME}/",
        "${HOME}/pything/",
        "${HOME}/git/"
      ],
      "enabled": true
    },
    "fetch": {
      "type": "local",
      "command": [
        "uvx",
        "mcp-server-fetch"
      ],
      "enabled": true
    },
    "git": {
      "type": "local",
      "command": [
        "uvx",
        "mcp-server-git"
      ],
      "enabled": true
    },
    "memory": {
      "type": "local",
      "command": [
        "npx",
        "-y",
        "@modelcontextprotocol/server-memory"
      ],
      "enabled": true
    },
    "playwright": {
      "type": "local",
      "command": [
        "npx",
        "-y",
        "@playwright/mcp@0.0.78",
        "--browser",
        "chrome",
        "--isolated",
        "--viewport-size",
        "1440x900",
        "--caps",
        "vision,pdf",
        "--block-service-workers"
      ],
      "enabled": true,
      "timeout": 30000,
      "environment": {}
    }
  },
  "plugin": [
    "@guard22/opencode-multi-auth-codex@1.4.3"
  ],
  "skills": {
    "paths": [
      "${HOME}/.codex/skills"
    ]
  },
  "model": "openai/gpt-5.5",
  "small_model": "openai/gpt-5.5"
}
