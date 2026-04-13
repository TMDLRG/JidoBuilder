defmodule JidoBuilderWeb.Api.V1.OpenApiController do
  @moduledoc """
  Story 4.4 — Serves the OpenAPI specification at /api/v1/openapi.json
  """
  use JidoBuilderWeb, :controller

  def spec(conn, _params) do
    spec = build_spec()
    json(conn, spec)
  end

  defp build_spec do
    %{
      openapi: "3.0.3",
      info: %{
        title: "JidoBuilder API",
        version: "2.0.0",
        description: "JidoBuilder agent platform API. REST endpoints for core CRUD, MCP (Model Context Protocol) for AI tool access with 13 tools covering agents, templates, workflows, Active Inference, LLM, notebooks, factory, skills, solutions, and library."
      },
      servers: [%{url: "/api/v1"}],
      security: [%{"bearerAuth" => []}],
      components: %{
        securitySchemes: %{
          bearerAuth: %{type: "http", scheme: "bearer", description: "API key from workspace settings"}
        }
      },
      paths: %{
        "/agents" => %{
          get: endpoint("List agents", "Returns all running agents in the workspace"),
          post: endpoint("Hire agent", "Creates and starts a new agent", body: agent_create_body())
        },
        "/agents/{id}" => %{
          get: endpoint("Show agent", "Returns details of a single agent", params: [id_param()]),
          delete: endpoint("Stop agent", "Stops and deactivates an agent", params: [id_param()])
        },
        "/agents/{id}/dispatch" => %{
          post: endpoint("Dispatch signal", "Sends a signal to an agent and returns execution result",
            params: [id_param()],
            body: dispatch_body()
          )
        },
        "/templates" => %{
          get: endpoint("List templates", "Returns all templates in the workspace"),
          post: endpoint("Create template", "Creates a new agent template", body: template_body())
        },
        "/templates/{id}" => %{
          get: endpoint("Show template", "Returns template details", params: [id_param()]),
          delete: endpoint("Delete template", "Deletes a template", params: [id_param()])
        },
        "/workflows" => %{
          get: endpoint("List workflows", "Returns all workflows in the workspace"),
          post: endpoint("Create workflow", "Creates a new workflow", body: workflow_body())
        },
        "/workflows/{id}" => %{
          get: endpoint("Show workflow", "Returns workflow details", params: [id_param()])
        },
        "/signals" => %{
          get: endpoint("Signal history", "Returns recent signal dispatch logs")
        },
        "/errors" => %{
          get: endpoint("Error history", "Returns recent error logs")
        },
        "/correlation/{id}" => %{
          get: endpoint("Correlation trace", "Returns all logs for a correlation ID", params: [id_param()])
        },
        "/mcp" => %{
          post: endpoint("MCP JSON-RPC", "Model Context Protocol handler for AI tool calls. Supports 13 tools: jido_agent, jido_template, jido_workflow, jido_observe, jido_workspace, jido_help, jido_factory, jido_skill, jido_llm, jido_active_inference, jido_notebook, jido_library, jido_solution",
            body: mcp_body()
          )
        },
        "/mcp/sse" => %{
          get: endpoint("MCP SSE", "Server-Sent Events stream for MCP real-time communication")
        },
        "/mcp/messages" => %{
          post: endpoint("MCP Messages", "Send messages to an active MCP SSE session")
        }
      },
      "x-mcp-tools": mcp_tools_list()
    }
  end

  defp endpoint(summary, description, opts \\ []) do
    base = %{summary: summary, description: description, responses: %{"200" => %{description: "Success"}}}
    base = if opts[:params], do: Map.put(base, :parameters, opts[:params]), else: base
    base = if opts[:body], do: Map.put(base, :requestBody, opts[:body]), else: base
    base
  end

  defp id_param, do: %{name: "id", in: "path", required: true, schema: %{type: "string"}}

  defp agent_create_body do
    %{required: true, content: %{"application/json" => %{schema: %{
      type: "object",
      properties: %{name: %{type: "string"}, template_id: %{type: "integer", nullable: true}},
      required: ["name"]
    }}}}
  end

  defp dispatch_body do
    %{required: true, content: %{"application/json" => %{schema: %{
      type: "object",
      properties: %{signal_type: %{type: "string"}, payload: %{type: "object"}},
      required: ["signal_type"]
    }}}}
  end

  defp template_body do
    %{required: true, content: %{"application/json" => %{schema: %{
      type: "object",
      properties: %{name: %{type: "string"}, slug: %{type: "string"}, version: %{type: "string"}, status: %{type: "string"}},
      required: ["name", "slug", "version", "status"]
    }}}}
  end

  defp workflow_body do
    %{required: true, content: %{"application/json" => %{schema: %{
      type: "object",
      properties: %{name: %{type: "string"}, description: %{type: "string"}},
      required: ["name"]
    }}}}
  end

  defp mcp_body do
    %{required: true, content: %{"application/json" => %{schema: %{
      type: "object",
      properties: %{
        jsonrpc: %{type: "string", enum: ["2.0"]},
        id: %{type: "integer"},
        method: %{type: "string"},
        params: %{type: "object"}
      },
      required: ["jsonrpc", "id", "method"]
    }}}}
  end

  defp mcp_tools_list do
    [
      %{name: "jido_agent", actions: ["hire", "list", "get", "stop", "dispatch"]},
      %{name: "jido_template", actions: ["create", "list", "get", "delete", "list_routes"]},
      %{name: "jido_workflow", actions: ["create", "list", "get", "run"]},
      %{name: "jido_observe", actions: ["signals", "errors", "correlation", "dashboard"]},
      %{name: "jido_workspace", actions: ["list", "create"]},
      %{name: "jido_help", actions: ["guide", "tool_help", "glossary", "examples"]},
      %{name: "jido_factory", actions: ["compose", "clone", "version", "diff", "deploy_team"]},
      %{name: "jido_skill", actions: ["list", "get", "categories", "by_category"]},
      %{name: "jido_llm", actions: ["providers", "configure", "chat"]},
      %{name: "jido_active_inference", actions: ["presets", "create_model", "evaluate"]},
      %{name: "jido_notebook", actions: ["create", "run_cell", "list_cells", "export", "reset"]},
      %{name: "jido_library", actions: ["browse_actions", "browse_skills", "browse_solutions", "categories", "search"]},
      %{name: "jido_solution", actions: ["list", "get", "deploy", "teardown"]}
    ]
  end
end
