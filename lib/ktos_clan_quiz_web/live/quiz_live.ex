defmodule KtosClanQuizWeb.QuizLive do
  require Logger
  use KtosClanQuizWeb, :live_view

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
      |> assign(:show_welcome_message, true)

    {:ok, socket}
  end

  # This function renders the HTML for our LiveView
  # lib/my_clan_quiz_web/live/quiz_live.ex

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4 max-w-lg">
      <h1 class="text-3xl font-bold mb-6 text-center">The Sorting Quiz</h1>

      <%= if assigns.show_welcome_message do %>
        <div class="bg-blue-100 border-l-4 border-blue-500 text-blue-700 p-4 mb-4" role="alert">
          <p class="font-bold">Welcome, brave adventurer!</p>
          <p>Prepare to answer questions that will reveal your true nature.</p>
        </div>
      <% end %>

      <div class="chat-window bg-white shadow-md rounded-lg p-6 mb-6 h-96 overflow-y-auto flex flex-col">
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
    # Basic validation: ensure the user actually typed something
    if String.trim(response) == "" do
      {:noreply, put_flash(socket, :error, "Please provide an answer before proceeding.")}
    else
      %{
        questions: all_questions,
        current_question_index: current_index,
        chat_history: current_chat_history
      } = socket.assigns

      # Get the question that was just answered
      answered_question = Enum.at(all_questions, current_index)

      # Update chat history with both question and user's answer
      updated_chat_history =
        current_chat_history ++
          [%{type: :question, text: answered_question}] ++
          [%{type: :response, text: response}]

      # Store the answer to this specific question (important for AI later)
      # We'll need a way to store answers linked to questions. For now, let's keep it simple
      # by just adding to chat history. Later, you might want a list of {:question, "...", :answer, "..."} tuples.
      # For full AI analysis, we'll collect all answers at the end.

      next_index = current_index + 1
      # total_questions = length(all_questions)
      total_questions = 3

      socket =
        socket
        # Clear input
        |> assign(:user_response, "")
        |> assign(:chat_history, updated_chat_history)
        # Hide welcome after first response
        |> assign(:show_welcome_message, false)

      if next_index < total_questions do
        # More questions left, move to next question
        {:noreply, assign(socket, :current_question_index, next_index)}
      else
        # All questions answered, quiz is complete!
        # This is where you'll trigger the AI processing.

        # Start an asynchronous task to simulate AI processing
        # <--- CAPTURE THE LIVEVIEW'S PID HERE
        live_view_pid = self()

        Task.async(fn ->
          # Simulate a 3-second delay for AI processing
          Process.sleep(3000)

          Logger.info(
            "Task: About to send AI result message to LiveView PID: #{inspect(live_view_pid)}"
          )

          # Send the message to the CAPTURED LiveView PID
          send(
            # <--- USE THE CAPTURED PID HERE
            live_view_pid,
            {:ai_result, "The Kobuco clan",
             "Your strong determination and unwavering resolve to achieve a goal or resist temptation align perfectly with the iron will of the Kobuco clan."}
          )

          Logger.info("Task: AI result message sent.")
        end)

        {:noreply,
         socket
         |> assign(:quiz_complete, true)
         # Keep index at end to indicate completion
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
      # Show welcome again on reset
      |> assign(:show_welcome_message, true)

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
end
