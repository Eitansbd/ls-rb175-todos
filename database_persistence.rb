require "pg"
require "pry"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "todos")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement} #{params}"

    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1"

    result = query(sql, id)

    todo_sql = "SELECT * FROM todos WHERE list_id = $1"
    todo_result = query(todo_sql, id)
    todos = find_todos_for_list(id)

    tuple = result.first
    { id: tuple["id"], name: tuple["name"], todos: todos }
  end

  def all_lists
    sql = "SELECT * FROM lists;"

    result = query(sql)

    result.map do |tuple|
      list_id = tuple["id"].to_i
      todos = find_todos_for_list(list_id)
      { id: list_id, name: tuple["name"], todos: todos }
    end
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1)"

    query(sql, list_name)
    # list_id = next_list_id
    # all_lists << { id: list_id, name: list_name, todos: [] }
  end

  def delete_list(list_id)
    sql = "DELETE FROM todos WHERE list_id = $1"
    query(sql, list_id)
    sql = "DELETE FROM lists WHERE id = $1"
    query(sql, list_id)
    # list = find_list(list_id)
    # @session[:lists].delete(list)
  end

  def create_new_todo(list_id, todo_name)
    sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2)"

    query(sql, todo_name, list_id)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2"

    query(sql, todo_id, list_id)
  end

  def update_list_name(list_id, new_list_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2"
    query(sql, new_list_name, list_id)
  end

  def todo_name_exists?(name, list_id)
    sql = "SELECT * FROM todos WHERE name = $1 AND list_id = $2"

    result = query(sql, name, list_id)
    !result.ntuples.zero?
  end

  def list_name_exists?(name)
    sql = "SELECT * FROM lists WHERE name = $1"

    result = query(sql, name)
    !result.ntuples.zero?
  end

  def change_todo_status(list_id, todo_id, status)
    sql = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3"

    query(sql, status, todo_id, list_id)
  end

  def mark_all_todos_completed(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1"

    query(sql, list_id)
  end

  private

  def find_todos_for_list(list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1"
    result = query(sql, list_id)
    result.map do |tuple|
        { id: tuple["id"],
          name: tuple["name"],
          completed: tuple["completed"] == "t" }
    end
  end
end