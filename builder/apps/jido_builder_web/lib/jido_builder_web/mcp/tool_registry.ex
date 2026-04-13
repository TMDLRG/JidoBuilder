defmodule JidoBuilderWeb.MCP.ToolRegistry do
  @moduledoc """
  Registry of MCP tools. Each tool has a name, description, input schema,
  and handler function. Tools use sub-actions pattern: each tool supports
  an `action` parameter that selects the operation.
  """

  @tools [
    %{
      name: "jido_agent",
      description: "Manage Jido agents: hire, list, get, stop, dispatch_signal, get_state",
      input_schema: %{
        type: "object",
        properties: %{
          action: %{type: "string", enum: ["hire", "list", "get", "stop", "dispatch", "help"], description: "Action to perform"},
          name: %{type: "string", description: "Agent name (for hire)"},
          id: %{type: "string", description: "Agent name/ID (for get/stop/dispatch)"},
          template_id: %{type: "integer", description: "Template ID (for hire)"},
          signal_type: %{type: "string", description: "Signal type (for dispatch)"},
          payload: %{type: "object", description: "Signal payload (for dispatch)"}
        },
        required: ["action"]
      },
      handler: JidoBuilderWeb.MCP.Tools.AgentTool
    },
    %{
      name: "jido_template",
      description: "Manage agent templates: create, list, get, delete, list_routes",
      input_schema: %{
        type: "object",
        properties: %{
          action: %{type: "string", enum: ["create", "list", "get", "delete", "list_routes", "help"]},
          id: %{type: "integer", description: "Template ID"},
          name: %{type: "string"}, slug: %{type: "string"},
          version: %{type: "string"}, status: %{type: "string"}
        },
        required: ["action"]
      },
      handler: JidoBuilderWeb.MCP.Tools.TemplateTool
    },
    %{
      name: "jido_workflow",
      description: "Manage workflows: create, list, get, run, get_results",
      input_schema: %{
        type: "object",
        properties: %{
          action: %{type: "string", enum: ["create", "list", "get", "run", "help"]},
          id: %{type: "integer"}, name: %{type: "string"}, description: %{type: "string"}
        },
        required: ["action"]
      },
      handler: JidoBuilderWeb.MCP.Tools.WorkflowTool
    },
    %{
      name: "jido_observe",
      description: "Query observability data: signals, errors, correlation traces, dashboard KPIs",
      input_schema: %{
        type: "object",
        properties: %{
          action: %{type: "string", enum: ["signals", "errors", "correlation", "dashboard", "help"]},
          correlation_id: %{type: "string"}, limit: %{type: "integer"}
        },
        required: ["action"]
      },
      handler: JidoBuilderWeb.MCP.Tools.ObserveTool
    },
    %{
      name: "jido_workspace",
      description: "Manage workspaces: list, create, settings",
      input_schema: %{
        type: "object",
        properties: %{
          action: %{type: "string", enum: ["list", "create", "help"]},
          name: %{type: "string"}, slug: %{type: "string"}
        },
        required: ["action"]
      },
      handler: JidoBuilderWeb.MCP.Tools.WorkspaceTool
    },
    %{
      name: "jido_help",
      description: "Get help, tool documentation, glossary, and examples",
      input_schema: %{
        type: "object",
        properties: %{
          action: %{type: "string", enum: ["guide", "tool_help", "glossary", "examples"]},
          tool: %{type: "string", description: "Tool name to get help for"}
        },
        required: ["action"]
      },
      handler: JidoBuilderWeb.MCP.Tools.HelpTool
    },
    %{
      name: "jido_factory",
      description: "Agent Factory: compose templates, clone, version, deploy teams",
      input_schema: %{
        type: "object",
        properties: %{
          action: %{type: "string", enum: ["compose", "clone", "version", "diff", "deploy_team", "help"]},
          templates: %{type: "array", description: "Template definitions to compose"},
          config: %{type: "object"}, overrides: %{type: "object"},
          old: %{type: "object"}, new: %{type: "object"},
          solution: %{type: "string"}, changelog: %{type: "string"}
        },
        required: ["action"]
      },
      handler: JidoBuilderWeb.MCP.Tools.FactoryTool
    },
    %{
      name: "jido_skill",
      description: "Manage skills: list, get, categories",
      input_schema: %{
        type: "object",
        properties: %{
          action: %{type: "string", enum: ["list", "get", "categories", "by_category", "help"]},
          slug: %{type: "string"}, category: %{type: "string"}
        },
        required: ["action"]
      },
      handler: JidoBuilderWeb.MCP.Tools.SkillTool
    },
    %{
      name: "jido_llm",
      description: "LLM configuration: providers, configure, chat",
      input_schema: %{
        type: "object",
        properties: %{
          action: %{type: "string", enum: ["providers", "configure", "chat", "help"]},
          provider: %{type: "string"}, model: %{type: "string"},
          message: %{type: "string"}, temperature: %{type: "number"},
          max_tokens: %{type: "integer"}, system: %{type: "string"}
        },
        required: ["action"]
      },
      handler: JidoBuilderWeb.MCP.Tools.LlmTool
    },
    %{
      name: "jido_active_inference",
      description: "Active Inference: create models, evaluate policies, update beliefs",
      input_schema: %{
        type: "object",
        properties: %{
          action: %{type: "string", enum: ["presets", "create_model", "evaluate", "help"]},
          preset: %{type: "string"}, observation: %{type: "integer"}
        },
        required: ["action"]
      },
      handler: JidoBuilderWeb.MCP.Tools.ActiveInferenceTool
    },
    %{
      name: "jido_notebook",
      description: "Interactive notebook: create, run cells, export code",
      input_schema: %{
        type: "object",
        properties: %{
          action: %{type: "string", enum: ["create", "run_cell", "list_cells", "export", "reset", "help"]},
          name: %{type: "string"}, code: %{type: "string"}, module_name: %{type: "string"}
        },
        required: ["action"]
      },
      handler: JidoBuilderWeb.MCP.Tools.NotebookTool
    },
    %{
      name: "jido_library",
      description: "Browse template library: actions, skills, solutions, search",
      input_schema: %{
        type: "object",
        properties: %{
          action: %{type: "string", enum: ["browse_actions", "browse_skills", "browse_solutions", "categories", "search", "help"]},
          category: %{type: "string"}, query: %{type: "string"}
        },
        required: ["action"]
      },
      handler: JidoBuilderWeb.MCP.Tools.LibraryTool
    },
    %{
      name: "jido_solution",
      description: "Composite solutions: list, deploy, teardown",
      input_schema: %{
        type: "object",
        properties: %{
          action: %{type: "string", enum: ["list", "get", "deploy", "teardown", "help"]},
          slug: %{type: "string"}
        },
        required: ["action"]
      },
      handler: JidoBuilderWeb.MCP.Tools.SolutionTool
    }
  ]

  @tool_map Map.new(@tools, fn t -> {t.name, t} end)

  @spec list() :: [map()]
  def list, do: @tools

  @spec get(String.t()) :: map() | nil
  def get(name), do: Map.get(@tool_map, name)

  @spec list_for_mcp() :: [map()]
  def list_for_mcp do
    Enum.map(@tools, fn t ->
      %{
        name: t.name,
        description: t.description,
        inputSchema: t.input_schema
      }
    end)
  end
end
