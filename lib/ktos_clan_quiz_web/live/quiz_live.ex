defmodule KtosClanQuizWeb.QuizLive do
  require Logger
  use KtosClanQuizWeb, :live_view
  alias KtosClanQuiz.AIAgent

  # Define your clans here. These descriptions are crucial for the AI.
  # Ensure these are accurate and descriptive of your intended clans.
  @clans %{
    "The Kobuco Clan" =>
      "This clan harnessed the brutal igneous power of the Brulma constellation, becoming expert blacksmiths known for forging legendary weapons. Their members bear ritualistic burn marks and now survive by recycling metal waste to create droid parts.",
    "The Ziwo Clan" =>
      "Unconnected to spiritual energy and lacking tails and celestial diamonds, the Ziwo prioritize material accumulation as a measure of individual progress. Once powerful merchants, they are now largely found in casinos and are deeply indebted, with members like Rust serving as bounty hunters to repay family debts.",
    "The Kummel Clan" =>
      "This ancestral clan channeled the energy of the Emole constellation to master the art of locating potable water from deep underground aquifers, building extensive aqueducts and pulley systems. They were also known for their funerary chants, utilizing tunnel acoustics to amplify their healing choruses.",
    "The Kutaro Clan" =>
      "Drawing energy from the Ara constellation, the Kutaros became adept at high-altitude cultivation, producing food, medicinal plants, and floral arrangements despite perpetual twilight. They constructed impressive elevated structures reminiscent of floating gardens.",
    "The Kundelli Clan" =>
      "Channeling the energy of the Candello constellation, the Kundellis developed the ancestral K-to language and meticulously recorded their history and teachings on papyri. They constructed a secure library atop Mount Obara to safeguard their clan's secrets.",
    "The Kutobi Clan" =>
      "The Kutobi drew power from the Tobias constellation, embodying curiosity, vision, and ingenuity. Historically the religious and ceremonial leaders, they crafted intricate glass art and were renowned for their respected prophets, though their descendants now suffer from unsettling visions and madness.",
    "The Selego Clan" =>
      "This clan embraced the concept of mortality and the cycle of life and death, finding profound meaning in transitions and the impermanence of existence. They are said to possess a unique understanding of the veil between worlds, guiding souls and ensuring peaceful passage."
  }

  # This function initializes the state of our LiveView
  def mount(_params, _session, socket) do
    questions = [
      "Describe a dream you've had that felt particularly vivid or meaningful.",
      "What is your greatest fear, and how do you confront it?",
      "You discover a hidden ancient artifact. What's the first thing you do with it?",
      "If you could have any magical ability, what would it be and why?",
      "How do you react when faced with a morally ambiguous decision?",
      "What kind of legacy do you wish to leave behind?",
      "You are offered immense power but at a great personal cost. Do you accept?",
      "What brings you the most profound sense of peace or contentment?",
      "How do you approach learning new and complex information?",
      "When facing an unknown challenge, what's your primary instinct?"
    ]

    socket =
      socket
      # Store all questions
      |> assign(:questions, questions)
      # Start at the first question
      |> assign(:current_question_index, 0)
      |> assign(:user_response, "")
      |> assign(:chat_history, [])
      # New assign to track quiz completion
      |> assign(:quiz_complete, false)
      # To store the final clan, once determined by AI
      |> assign(:clan_result, nil)
      # To store the AI's explanation
      |> assign(:ai_reasoning, nil)
      # To show loading state during AI call
      |> assign(:ai_processing, false)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <h1 class="text-3xl font-bold mb-6 text-center">The Sorting Quiz</h1>

      <div class="bg-blue-100 border-l-4 border-blue-500 text-blue-700 p-4 mb-4" role="alert">
        <p class="font-bold">Welcome, brave adventurer!</p>
        <p>Prepare to answer questions that will reveal your true nature.</p>
      </div>

      <div
        id="chat-window"
        phx-hook="ChatScroll"
        class="chat-window bg-white shadow-md rounded-lg p-6 mb-6 h-96 overflow-y-auto flex flex-col"
      >
        <%= for item <- assigns.chat_history do %>
          <%= if item.type == :question do %>
            <div class="bg-gray-200 p-3 rounded-lg self-start my-2">
              <p class="font-semibold">Quiz Master:</p>
              <p>{item.text}</p>
            </div>
          <% else %>
            <div class="bg-green-100 p-3 rounded-lg self-end my-2 text-right">
              <p class="font-semibold">You:</p>
              <p>{item.text}</p>
            </div>
          <% end %>
        <% end %>

        <% # Display the current question or quiz complete message %>
        <%= if assigns.quiz_complete do %>
          <div class="bg-purple-100 p-3 rounded-lg self-center my-2 text-center text-purple-800 font-bold text-xl mt-auto">
            <h3>Quiz Complete!</h3>
            <%= if assigns.ai_processing do %>
              <p>Consulting the ancient scrolls...</p>
              <div class="spinner border-t-4 border-purple-500 border-solid rounded-full w-8 h-8 mx-auto mt-2 animate-spin">
              </div>
            <% else %>
              <p>You belong to: **{assigns.clan_result}**</p>
              <p class="text-sm font-normal">{assigns.ai_reasoning}</p>
            <% end %>
          </div>
        <% else %>
          <div class="bg-gray-200 p-3 rounded-lg self-start my-2 mt-auto">
            <p class="font-semibold">Quiz Master:</p>
            <p>{Enum.at(assigns.questions, assigns.current_question_index)}</p>
          </div>
        <% end %>
      </div>

      <% # Conditionally render the input form or the reset button based on states %>
      <%= if not assigns.quiz_complete and not assigns.ai_processing do %>
        <form phx-submit="submit_response" class="flex mt-4">
          <textarea
            id="user_response_input"
            name="user_response"
            rows="3"
            phx-value-input={assigns.user_response}
            phx-change="update_response"
            class="flex-grow border border-gray-300 rounded-l-lg p-3 focus:outline-none focus:ring-2 focus:ring-purple-500"
            placeholder="Type your answer here..."
          ></textarea>
          <button
            type="submit"
            class="bg-purple-600 text-white px-6 py-3 rounded-r-lg hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500"
          >
            Send
          </button>
        </form>
      <% end %>

      <% # Display the reset button ONLY if the quiz is complete AND AI is NOT processing %>
      <%= if assigns.quiz_complete and not assigns.ai_processing do %>
        <button
          phx-click="reset_quiz"
          class="mt-4 w-full bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          Start New Quiz
        </button>
      <% end %>
    </div>
    """
  end

  # This function handles updates from the textarea (as the user types)
  # phx-change="update_response" triggers this
  def handle_event("update_response", %{"user_response" => response}, socket) do
    {:noreply, assign(socket, :user_response, response)}
  end

  # This function handles the form submission
  # phx-submit="submit_response" triggers this
  def handle_event("submit_response", %{"user_response" => response}, socket) do
    if String.trim(response) == "" do
      # ... (your existing validation) ...
    else
      %{
        questions: all_questions,
        current_question_index: current_index,
        chat_history: current_chat_history
      } = socket.assigns

      answered_question = Enum.at(all_questions, current_index)

      updated_chat_history =
        current_chat_history ++
          [%{type: :question, text: answered_question}] ++
          [%{type: :response, text: response}]

      next_index = current_index + 1
      total_questions = length(all_questions)

      socket =
        socket
        |> assign(:user_response, "")
        # <--- Make sure this assign is done *before* Task.async
        |> assign(:chat_history, updated_chat_history)

      if next_index < total_questions do
        # More questions left, move to next question
        {:noreply, assign(socket, :current_question_index, next_index)}
      else
        # All questions answered, quiz is complete!
        live_view_pid = self()

        Task.async(fn ->
          # Prepare the full context of answers for the AI
          # Use the updated_chat_history which contains ALL responses
          # <--- Pass updated_chat_history and @clans
          full_prompt_text = build_ai_prompt(updated_chat_history, @clans)

          case AIAgent.get_clan_prediction(full_prompt_text) do
            {:ok, %{clan: clan, reasoning: reasoning}} ->
              send(live_view_pid, {:ai_result, clan, reasoning})

            {:error, error_reason} ->
              Logger.error("Error from AI Agent: #{inspect(error_reason)}")
              # Send an error message back
              send(live_view_pid, {:ai_error, error_reason})
          end
        end)

        {:noreply,
         socket
         |> assign(:quiz_complete, true)
         |> assign(:current_question_index, next_index)
         # Show AI processing state
         |> assign(:ai_processing, true)
         |> put_flash(:info, "Quiz complete! Analyzing your responses...")}
      end
    end
  end

  def handle_event("reset_quiz", _value, socket) do
    # Reset all relevant assigns to their initial state
    socket =
      socket
      |> assign(:current_question_index, 0)
      |> assign(:user_response, "")
      |> assign(:chat_history, [])
      |> assign(:quiz_complete, false)
      |> assign(:clan_result, nil)
      |> assign(:ai_reasoning, nil)
      |> assign(:ai_processing, false)

    {:noreply, socket}
  end

  # This function handles messages sent to the LiveView process
  # It specifically matches on the message we sent from our Task
  def handle_info({:ai_result, clan, reasoning}, socket) do
    # <--- ADD THIS LINE
    Logger.info("LiveView: Received AI result. Clan: #{clan}")

    # Update the socket with the AI's result and mark processing as complete
    socket =
      socket
      |> assign(:clan_result, clan)
      |> assign(:ai_reasoning, reasoning)
      # Stop showing the spinner
      |> assign(:ai_processing, false)
      |> put_flash(:success, "Your clan has been determined!")

    {:noreply, socket}
  end

  # This new clause will catch any other messages that the LiveView process might receive
  # and simply ignore them, preventing a FunctionClauseError.
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  # Helper function to build the AI prompt from chat history and clan descriptions
  defp build_ai_prompt(chat_history, clans) do
    # Extract only the question/response pairs that matter for the quiz
    # The AI needs the full context of all interactions
    quiz_interactions =
      Enum.map_join(chat_history, "\n\n", fn
        %{type: :question, text: q} -> "Question: #{q}"
        %{type: :response, text: r} -> "Your Answer: #{r}"
        # Ignore other types if any, though your chat history should only have question/response
        _ -> ""
      end)

    clan_descriptions =
      Enum.map_join(clans, "\n", fn {name, desc} -> "#{name}: #{desc}" end)

    """
    You are a mystical and ancient Sorting Hat for a new, unique fantasy universe.
    Your purpose is to discern a user's inherent qualities and assign them to one of the predefined clans.
    Your output MUST ONLY contain the clan and a concise Reason for the assignment, following the exact format: 'clan: [clan Name]\nReasoning: [Reason]'.
    Do not add any other conversational text or preamble.

    Here are the available clans and their descriptions:
    #{clan_descriptions}

    Here is the user's interaction with the quiz:
    #{quiz_interactions}

    Based on these responses, which clan does the user belong to?
    """
  end
end
