/// Represents the different states a ViewModel can be in,
/// which the View can then use to render the appropriate UI.
enum ViewState {
  /// The initial state, or the state after a successful operation.
  Idle,

  /// The ViewModel is busy performing an asynchronous operation (e.g., a network call).
  /// The View should show a loading indicator.
  Busy,

  /// An error has occurred. The View should show an error message.
  Error,

  /// A specific state to signify a successful one-time event, like a successful login.
  /// This is useful for triggering navigation or showing a success message.
  Success,
}