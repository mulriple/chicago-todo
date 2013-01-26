window.todoApp =
  Models: {}
  Collections: {}
  Views: {}

class todoApp.Models.Todo extends Backbone.Model
  urlRoot: '/todos/index'

  defaults:
    title: "empty"
    done: false

  initialize: ->
    if not @get("order")
      @set("order": todoApp.todos.nextOrder())

  toggle: ->
    @save(
      done: not @get "done"
      )

class todoApp.Collections.TodoList extends Backbone.Collection
  url: '/todos/index'
  model: todoApp.Models.Todo

  done: ->
    @filter (todo) ->
      todo.get "done"

  remaining: ->
    @without.apply(@, @done())

  nextOrder: ->
    if not @length then return 1
    return @last().get("order") + 1

  comparator: (todo) ->
    @get("order")

class todoApp.Views.TodoView extends Backbone.View
  tagName: "li"
  template: _.template($('#item-template').html()),

  events:
    "click .toggle": "toggleDone"
    "dblclick .view": "edit"
    "click a.destroy": "clear"
    "keypress .edit": "updateOnEnter",
    "blur .edit": "close"

  initialize: ->
    @listenTo @model, 'change', @render
    @listenTo @model, 'destroy', @remove

  render: ->
    @$el.html(@template(@model.toJSON()))
    @$el.toggleClass('done', @model.get('done'))
    @input = @$('.edit')
    @

  toggleDone: ->
    @model.toggle()

  edit: ->
    @$el.addClass("editing")
    @input.focus()

  close: ->
    value = @input.val()
    if not value
      @clear()
    else
      @model.save({title: value})
      @$el.removeClass("editing")

  clear: ->
    @model.destroy()

  updateOnEnter: (event) ->
    if event.keyCode == 13
      @close()


class todoApp.Views.AppView extends Backbone.View
  el: $("#todoapp")
  statsTemplate: _.template($("#stats-template").html())

  events:
    "keypress #new-todo": "createOnEnter"
    "click #clear-completed": "clearCompleted"
    "click #toggle-all": "toggleAllComplete"

  initialize: ->
    @input = @$("#new-todo")
    @allCheckbox = @$("#toggle-all")[0]

    @listenTo todoApp.todos, 'add', @addOne
    @listenTo todoApp.todos, 'reset', @addAll
    @listenTo todoApp.todos, 'all', @render

    @footer = @$('footer')
    @main = $('#main')

    todoApp.todos.fetch()

  render: ->
    done = todoApp.todos.done().length
    remaining = todoApp.todos.remaining().length

    if todoApp.todos.length
      @main.show()
      @footer.show()
      @footer.html(@statsTemplate({done: done, remaining: remaining}))
    else
      @main.hide()
      @footer.hide()

    @allCheckbox.checked = not remaining

  addOne: (todo) ->
    view = new todoApp.Views.TodoView({model: todo})
    @$('#todo-list').append(view.render().el);

  addAll: ->
    todoApp.todos.each(@addOne, @)

  createOnEnter: (event) ->
    if event.keyCode != 13
      return
    if not @input.val()
      return

    todoApp.todos.create
      title: @input.val()
    @input.val('')

  clearCompleted: ->
    _.invoke(todoApp.todos.done(), 'destroy')
    false

  toggleAllComplete: ->
    done = @allCheckbox.checked
    todoApp.todos.each (todo) ->
      todo.save
        'done': done

todoApp.todos = new todoApp.Collections.TodoList
todoApp.app = new todoApp.Views.AppView

window.waitForMsg = (currentTime) ->
  $.ajax
    type: "GET"
    url: "/poll/getUpdate/#{currentTime}"
    async: true
    timeout: 5000000000
    success: (data) ->
      for object in data.objects
        if todoApp.todos.get(object.id)
          # updating
          r = todoApp.todos.get(object.id)
          r.set
            title: object.title
            done: object.done
            order: object.order
        else
          # creating
          t = new todoApp.Models.Todo
            id: object.id
            title: object.title
            done: object.done
            order: object.order
          todoApp.todos.add(t)
      window.timestamp = data.timestamp
      waitForMsg(data.timestamp)
    error: (error) ->
      waitForMsg(window.timestamp)

waitForMsg(window.timestamp)