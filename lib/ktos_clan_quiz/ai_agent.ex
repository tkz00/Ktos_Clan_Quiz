defmodule KtosClanQuiz.AIAgent do
  require Logger

  @house_model Application.compile_env(:ktos_clan_quiz, :openai_model, "gpt-3.5-turbo")

  @spec get_clan_prediction(any()) ::
          {:error, <<_::64, _::_*8>>} | {:ok, %{clan: binary(), reasoning: binary()}}
  def get_clan_prediction(prompt) do
    messages = [
      %{
        role: "system",
        content:
          "You are a mystical and ancient Sorting Hat for a new, unique fantasy fantasy universe. Your purpose is to discern a user's inherent qualities and assign them to one of the predefined clans. Your output MUST ONLY contain the Clan and a concise Reason for the assignment, following the exact format: 'Clan: [Clan Name]\\nReasoning: [Reason]'. Do not add any other conversational text or preamble."
      },
      %{role: "user", content: prompt}
    ]

    Logger.info("Sending prompt to OpenAI for model: #{@house_model}")

    # Initialize the OpenaiEx client
    client = openai_client()

    # Use the supervised client by its name
    case OpenaiEx.Chat.Completions.create(
           client,
           %{
             model: @house_model,
             messages: messages,
             temperature: 0.7,
             max_tokens: 200
           }
         ) do
      {:ok, %{"choices" => [%{"message" => %{"content" => ai_response_text}} | _rest]}} ->
        Logger.info("Received raw AI response: #{inspect(ai_response_text)}")
        parse_ai_response(ai_response_text)

      {:error, reason} ->
        Logger.error("OpenAI API Error: #{inspect(reason)}")
        {:error, "AI API call failed: #{inspect(reason)}"}

      other ->
        Logger.error("Unexpected OpenAI API response structure: #{inspect(other)}")
        {:error, "Unexpected AI response format"}
    end
  end

  defp openai_client do
    apikey = System.fetch_env!("OPENAI_API_KEY")
    Logger.info("Key: #{apikey}")
    OpenaiEx.new(apikey)
  end

  # Function to parse the AI's structured response
  defp parse_ai_response(text) do
    # Use Regex to extract Clan and Reasoning
    case Regex.run(~r/Clan:\s*(.+?)\nReasoning:\s*(.+)/s, text) do
      [_full_match, clan, reasoning] ->
        # Trim whitespace from extracted parts
        {:ok, %{clan: String.trim(clan), reasoning: String.trim(reasoning)}}

      _ ->
        Logger.warning("Could not parse AI response into expected format: #{text}")
        # Fallback for when AI doesn't follow the format perfectly
        {:error, "AI response parsing failed. Raw response: #{text}"}
    end
  end
end
