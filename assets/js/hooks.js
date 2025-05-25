// Define a general Hooks object that will hold all your LiveView hooks
let Hooks = {}

// Define the ChatScroll hook
Hooks.ChatScroll = {
    // `mounted()` is called once when the element is first added to the DOM (e.g., page load)
    mounted() {
        this.scrollToBottom();
    },
    // `updated()` is called every time the LiveView updates the element's content
    updated() {
        this.scrollToBottom();
    },
    // Helper function to perform the actual scroll
    scrollToBottom() {
        // `this.el` refers to the DOM element the hook is attached to (our chat-window div)
        // `scrollHeight` is the entire height of the content, even if it's not visible
        // Setting `scrollTop` to `scrollHeight` scrolls the element to its very bottom
        this.el.scrollTop = this.el.scrollHeight;
    }
}

// Export the Hooks object so it can be imported in app.js
export default Hooks;