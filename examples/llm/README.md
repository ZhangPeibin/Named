# LiteLLM vs Pydantic AI

两个可以离线运行的最小例子，用来理解这两类库的职责差别。

- `litellm_example.py`：只把 LiteLLM 当“多 provider 调用层”。你仍然自己写提示词、解析 JSON、校验字段。
- `pydantic_ai_example.py`：把 Pydantic AI 当“Agent 框架”。声明 `output_type=WordInfo`，框架负责约束输出、校验和重试。

## 运行

```sh
cd examples/llm
cp .env.example .env
uv sync

# 不需要 API key 的离线演示
uv run litellm_example.py --mock 树
uv run pydantic_ai_example.py --mock 树

# 调用真实模型（需要在 .env 里填 DEEPSEEK_API_KEY）
uv run litellm_example.py 树
uv run pydantic_ai_example.py 树
```

## 切换模型

两个文件使用不同的模型字符串格式：

```dotenv
# LiteLLM
LITELLM_MODEL=deepseek/deepseek-flash
# LITELLM_MODEL=openai/gpt-4o-mini
# LITELLM_MODEL=anthropic/claude-sonnet-5-5

# Pydantic AI
PYDANTIC_AI_MODEL=deepseek:deepseek-flash
# PYDANTIC_AI_MODEL=openai:gpt-4o-mini
# PYDANTIC_AI_MODEL=anthropic:claude-sonnet-5-5
```

对应的 API key 也要设置：`DEEPSEEK_API_KEY`、`OPENAI_API_KEY` 或 `ANTHROPIC_API_KEY`。

## 两个例子的关键区别

| 步骤 | LiteLLM 例子 | Pydantic AI 例子 |
| --- | --- | --- |
| 定义输出结构 | `WordInfo` Pydantic 模型 | `WordInfo` Pydantic 模型 |
| 约束模型输出 | 手写提示词 + `response_format` | `Agent(output_type=WordInfo)` |
| 解析 | `json.loads` | 框架自动完成 |
| 校验 | 手动 `model_validate` | 框架自动校验 |
| 失败重试 | 需要自己写 | 框架自动重试 |
| 多 provider | `deepseek/...`、`openai/...` | `deepseek:...`、`openai:...` |
| 主要价值 | 统一调用、路由、成本控制 | typed agent、工具、依赖注入、结构化输出 |

## 一句话

- **LiteLLM** 解决“请求怎么发给不同模型”。
- **Pydantic AI** 解决“Agent 怎么组织提示、工具、结构化输出和重试”。
- 两者可以组合：Pydantic AI 作为 Agent 层，LiteLLM 作为下面的网关。

## DeepSeek 注意点

DeepSeek V4 默认开启 thinking，开启时会拒绝强制 tool choice。Pydantic AI 例子在模型名以 `deepseek:` 开头时会设置 `thinking=False`，让结构化输出更可靠。
