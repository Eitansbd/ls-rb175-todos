require 'pry'
require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'
require_relative 'database_persistence'

configure do
  enable :sessions
  set :session_secret, 'sercet'
  set :erb, escape_html: true

end

configure(:development) do
  require 'sinatra/reloader'
  also_reload 'database_persistence.rb'
end

helpers do
  def todos_completed_count(list)
    list[:todos].select {|todo| todo[:completed]}.size
  end

  def list_complete?(list)
    number_completed = todos_completed_count(list)

    number_completed > 0 && number_completed == todos_count(list)
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_count(list)
    list[:todos].size
  end

  def sort_lists_by_complete(lists, &block)
    lists.sort_by { |list| list_complete?(list).to_s }
  end

  def sort_todos_by_complete(todos, &block)
    todos.sort_by { |todo| todo[:completed].to_s }
  end
end

HOME_PAGE = "/lists"



def load_list(id)
  list = @storage.find_list(id)

  return list if list

  session[:error] = "The specified list does not exist"
  redirect HOME_PAGE
end

before do
  @storage = DatabasePersistence.new(logger)
end

get '/' do
  redirect HOME_PAGE
end

# View list of lists
get '/lists' do
  @lists = @storage.all_lists
  erb :all_lists, layout: :layout
end

# Renders new list form
get '/lists/new' do
  erb :new_list
end

# Page for each todo list
get '/lists/:list_id' do
	@list = load_list(params[:list_id].to_i)
	erb :list
end

# Page for editing a todo list
get '/lists/:list_id/edit' do
  @list = load_list(params[:list_id].to_i)
  erb :edit_list
end

# Returns error if list name is invalid, otherwise nil
def error_for_list_name(name)
  if !(1..100).cover? name.size
    'The list name must be between 1 and 100 characters.'
  elsif @storage.list_name_exists?(name)
    'List name must be unique'
  end
end

# Creates a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    @storage.create_new_list(list_name)
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Edits a list
post '/lists/:list_id' do
  list_id = params[:list_id].to_i
  @list = load_list(list_id)

  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list
  else
    @storage.update_list_name(list_id, list_name)

    session[:success] = 'The list has been updated'
    redirect "/lists/#{@list[:id]}"
  end
end

# Deletes a list
post '/lists/:list_id/destroy' do
  @storage.delete_list(params[:list_id].to_i)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = 'The list has been removed'
    redirect '/lists'
  end
end


# returns error message if todo name invalid, nill otherwise
def error_for_todo_name(name, list_id)
  if !(1..100).cover? name.size
    'To do name must be between 1 and 100 characters'
  elsif @storage.todo_name_exists?(name, list_id)
    "You already have '#{name}' in this list."
  end
end

# Returns a todo item from a list based on the id given
def load_todo(list, id)
  list[:todos].find { |todo| todo[:id] == id }
end

# Add a todo to a list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_name = params[:todo].strip

  error = error_for_todo_name(todo_name, @list_id)
  if error
    session[:error] = error
    erb :list
  else
    @storage.create_new_todo(@list_id, todo_name)

    session[:success] = "'#{todo_name}' has been added to the list"
    redirect "/lists/#{@list[:id]}"
  end
end

# deletes a todo_item from a list
post '/lists/:list_id/todo/:todo_id/destroy' do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id]
  @list = load_list(list_id)
  todo_to_delete = load_todo(@list, todo_id)

  @storage.delete_todo_from_list(list_id, todo_id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "'#{todo_to_delete[:name]}' has been removed from the list"
    redirect "/lists/#{@list[:id]}"
  end
end

# Marks a todo item complete
post '/lists/:list_id/todo/:todo_id/toggle' do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  @list = load_list(list_id)

  todo_status = (params[:completed] == "true")

  @storage.change_todo_status(list_id, todo_id, todo_status)

  redirect "/lists/#{@list[:id]}"
end

# Marks all todos complete for a list
post '/lists/:list_id/complete_all' do
  list_id = params[:list_id].to_i
  @list = load_list(list_id)

  @storage.mark_all_todos_completed(list_id)

  session[:success] = "All Todo's have been marked completed"
  redirect "/lists/#{@list[:id]}"
end