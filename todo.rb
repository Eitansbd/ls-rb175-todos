require 'pry'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'sercet'
end

helpers do 
  def all_complete?(list)
    binding.pry
    list[:todos].all? {|todo| todo[:completed]}
  end
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# View list of lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Renders new list form
get '/lists/new' do
  erb :new_list
end

# Page for each todo list
get '/lists/:id' do |id|
	@id = id.to_i
	@list = session[:lists][@id]
	erb :list
end

# Page for editing a todo list
get '/lists/:id/edit' do |id|
	@id = id.to_i
  @list = session[:lists][@id]
	erb :edit_list
end

# Returns error is invalid name, otherwise nil
def error_for_list_name(name)
  if !(1..100).cover? name.size
    'The list name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name must be unique'
  end
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Edit a list 
post '/lists/:id' do |id|
  @id = id.to_i
  @list = session[:lists][@id]
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated'
    redirect "/lists/#{@id}"
  end
end

# Delete a list
post '/lists/:id/destroy' do |id|
  id.to_i
  session[:lists].delete_at(id.to_i)
  session[:success] = 'The list has been removed'
  redirect '/lists'
end


# returns error message if exists, nill otherwise
def error_for_todo_name(name, list)
  if !(1..100).cover? name.size
    'To do name must be between 1 and 100 characters'
  elsif list[:todos].any? { |todo| todo[:name] == name }
    "You already have '#{name}' in this list."
  end
end
# Add a list item
post '/lists/:id/todos' do |id|
  @id = id.to_i
  @list = session[:lists][@id]
  todo_name = params[:todo].strip

  error = error_for_todo_name(todo_name, @list)
  if error
    session[:error] = error
    erb :list
  else
    @list[:todos] << { name: todo_name, completed: false }
    session[:success] = "'#{todo_name}' has been added to the list"
    redirect "/lists/#{id}"
  end
end

# delete a todo_item
post '/lists/:id/todo/:todo_id/destroy' do |id, todo_id|
  @id = id.to_i
  @todo_id = todo_id.to_i
  @list = session[:lists][@id]
  deleted_todo = @list[:todos].delete_at(@todo_id)
  session[:success] = "'#{deleted_todo[:name]}' has been removed from the list"

  redirect "/lists/#{@id}"
end

# Mark a Todo Item Complete

post '/lists/:id/todo/:todo_id/toggle' do |id, todo_id|
  @id = id.to_i
  @todo_id = todo_id.to_i
  @list = session[:lists][@id]

  todo_status = (params[:completed] == "true")
  @list[:todos][@todo_id][:completed] = todo_status 
  
  redirect "/lists/#{@id}"
end

# Mark all todos complete for a list

post '/lists/:id/complete_all' do |id|
  @id = id.to_i
  @list = session[:lists][@id]

  @list[:todos].each { |todo| todo[:completed] = true}

  session[:success] = "All Todo's have been marked completed"
  redirect "/lists/#{@id}"
end