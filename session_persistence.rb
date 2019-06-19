class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def find_list(id)
    @session[:lists].find { |l| l[:id] == id }
  end

  def all_lists
    @session[:lists]
  end

  def create_new_list(list_name)
    list_id = next_list_id
    all_lists << { id: list_id, name: list_name, todos: [] }
  end

  def delete_list(list_id)
    list = find_list(list_id)
    @session[:lists].delete(list)
  end

  def create_new_todo(list_id, todo_name)
    list = find_list(list_id)

    todo_id = next_todo_id(list[:todos])
    list[:todos] << { id: todo_id, name: todo_name, completed: false }
  end

  def update_list_name(list_id, list_name)
    list = find_list(list_id)
    list[:name] = list_name
  end

  def todo_name_exists?(name, list_id)
    list = find_list(list_id)
    list[:todos].any? { |todo| todo[:name] == name }
  end

  def list_name_exists?(name)
    @session[:lists].any? { |list| list[:name] == name }
  end

  def delete_todo_from_list(list_id, todo_id)
    list = find_list(list_id)

    list[:todos].reject! { |todo| todo[:id] == todo_id }
  end

  def change_todo_status(list_id, todo_id, status)
    list = find_list(list_id)
    todo = list[:todos].find { |t| t[:id] == todo_id }

    todo[:completed] = status
  end

  def mark_all_todos_completed(list_id)
    list = load_list(list_id)
    list[:todos].each { |todo| todo[:completed] = true}
  end

  private

  def next_list_id
    max = @session[:lists].map { |list| list[:id] }.max || 0
    max + 1
  end

  def next_todo_id(todos)
    max = todos.map { |todo| todo[:id] }.max || 0
    max + 1
  end
end