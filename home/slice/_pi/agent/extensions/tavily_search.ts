import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const TAVILY_ENDPOINT = "https://api.tavily.com/search";

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web using Tavily. Returns relevant results with titles, " +
      "URLs, and content snippets. Use for current events, docs, or facts " +
      "not in the model's training data.",
    parameters: Type.Object({
      query: Type.String({ description: "The search query" }),
      max_results: Type.Optional(
        Type.Number({
          description: "Max number of results (1-10, default 5)",
          minimum: 1,
          maximum: 10,
        }),
      ),
      search_depth: Type.Optional(
        Type.Union([Type.Literal("basic"), Type.Literal("advanced")], {
          description: "Search depth: 'basic' (fast) or 'advanced' (thorough)",
        }),
      ),
      include_answer: Type.Optional(
        Type.Boolean({
          description: "Include an LLM-generated answer summary (default true)",
        }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const apiKey = process.env.TAVILY_API_KEY;
      if (!apiKey) {
        return {
          content: [
            {
              type: "text",
              text: "Error: TAVILY_API_KEY environment variable is not set.",
            },
          ],
          isError: true,
          details: {},
        };
      }

      let res: Response;
      try {
        res = await fetch(TAVILY_ENDPOINT, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${apiKey}`,
          },
          body: JSON.stringify({
            query: params.query,
            max_results: params.max_results ?? 5,
            search_depth: params.search_depth ?? "basic",
            include_answer: params.include_answer ?? true,
          }),
          signal,
        });
      } catch (err) {
        return {
          content: [
            { type: "text", text: `Request failed: ${(err as Error).message}` },
          ],
          isError: true,
          details: {},
        };
      }

      if (!res.ok) {
        const body = await res.text().catch(() => "");
        return {
          content: [
            {
              type: "text",
              text: `Tavily API error ${res.status}: ${body || res.statusText}`,
            },
          ],
          isError: true,
          details: {},
        };
      }

      const data = (await res.json()) as {
        answer?: string;
        results?: Array<{
          title?: string;
          url?: string;
          content?: string;
          score?: number;
        }>;
      };

      const parts: string[] = [];
      if (data.answer) parts.push(`Answer: ${data.answer}\n`);

      const results = data.results ?? [];
      if (results.length === 0 && !data.answer) {
        parts.push("No results found.");
      }
      results.forEach((r, i) => {
        parts.push(
          `${i + 1}. ${r.title ?? "(untitled)"}\n   ${r.url ?? ""}\n   ${
            r.content ?? ""
          }`,
        );
      });

      return {
        content: [{ type: "text", text: parts.join("\n") }],
        details: { query: params.query, resultCount: results.length },
      };
    },
  });
}
