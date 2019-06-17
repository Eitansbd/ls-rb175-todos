require 'pry'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'sercet'
  set :erb, escape_html: true
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
  list = session[:lists].find { |list| list[:id] == id }
  if list
    list
  else
    session[:error] = "The specified list does not exist"
    redirect HOME_PAGE
  end
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect HOME_PAGE
end

# View list of lists
get '/lists' do
  @lists = session[:lists]
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
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name must be unique'
  end
end

# Returns the next available id number for a list
def next_list_id
  max = session[:lists].map { |list| list[:id] }.max || 0
  max + 1
end

# Creates a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    list_id = next_list_id 
    session[:lists] << { id: list_id, name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Edits a list 
post '/lists/:list_id' do
  @list = load_list(params[:list_id].to_i)
  
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated'
    redirect "/lists/#{@list[:id]}"
  end
end

# Deletes a list
post '/lists/:list_id/destroy' do
  list_to_delete = load_list(params[:list_id].to_i)
  session[:lists].delete (list_to_delete)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else  
    session[:success] = 'The list has been removed'
    redirect '/lists'
  end
end


# returns error message if todo name invalid, nill otherwise
def error_for_todo_name(name, list)
  if !(1..100).cover? name.size
    'To do name must be between 1 and 100 characters'
  elsif list[:todos].any? { |todo| todo[:name] == name }
    "You already have '#{name}' in this list."
  end
end

# Returns the next available id number for a todo
def next_todo_id(todos)
  max = todos.map { |todo| todo[:id] }.max || 0
  max + 1
end

# Returns a todo item from a list based on the id given
def load_todo(list, id)
  list[:todos].find { |todo| todo[:id] == id }
end

# Add a todo to a list
post '/lists/:list_id/todos' do
  @list = load_list(params[:list_id].to_i)
  todo_name = params[:todo].strip

  error = error_for_todo_name(todo_name, @list)
  if error
    session[:error] = error
    erb :list
  else
    todo_id = next_todo_id(@list[:todos])
    @list[:todos] << { id: todo_id, name: todo_name, completed: false }
    session[:success] = "'#{todo_name}' has been added to the list"
    redirect "/lists/#{@list[:id]}"
  end
end

# deletes a todo_item from a list
post '/lists/:list_id/todo/:todo_id/destroy' do
  @list = load_list(params[:list_id].to_i)
  todo_to_delete = load_todo(@list, params[:todo_id].to_i)

  @list[:todos].delete(todo_to_delete)
  
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else  
    session[:success] = "'#{todo_to_delete[:name]}' has been removed from the list"
    redirect "/lists/#{@list[:id]}"
  end
end

# Marks a todo item complete
post '/lists/:list_id/todo/:todo_id/toggle' do 
  todo_id = params[:todo_id].to_i
  @list = load_list(params[:list_id].to_i)


  todo_status = (params[:completed] == "true")
  load_todo(@list, todo_id)[:completed] = todo_status 
  
  redirect "/lists/#{@list[:id]}"
end

# Marks all todos complete for a list
post '/lists/:list_id/complete_all' do |id|
  @list = load_list(params[:list_id].to_i)

  @list[:todos].each { |todo| todo[:completed] = true}

  session[:success] = "All Todo's have been marked completed"
  redirect "/lists/#{@list[:id]}"
end