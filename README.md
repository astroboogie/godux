<h1 align="center">
    <img src="icon.png" alt="Godot" height="60"/>
</h1>

<div align="center">
    A state management library written in GDScript inspired by <a href="https://redux.js.org">Redux</a>.
</div>

<div>&nbsp;</div>

Godux helps Godot developers consolidate game state into a single store. Communicating between nodes in your project becomes increasingly difficult the more complex your project becomes. Instead of littering all component nodes with game state, which can be unruly and confusing for larger projects, you can use a single source of information in order to easily access all data in your game from any node.

This is a continuation of Kenny Au's [godot-redux](https://github.com/glumpyfish/godot_redux).

Using the redux architecture allows for some interesting features:
* Saving and loading saved games becomes trivial.
* Undo/redoing actions.
* Event notifications.
* Quest tracking.

## Installation

* Add the files from the [src](src) folder to your project.
* Make `Store.gd` a singleton using "Scene > Project Settings > AutoLoad".

## Usage

A useful implementation is to create the following scripts as singletons:
* `ActionTypes.gd`
* `Actions.gd`
* `Reducers.gd`

For a demo, see the [examples](examples) folder.

### Store

The store is your main entry point for using Godux. You can create a store with `store.create()`.

#### State

The global state of your game is a `Dictionary` object in the store. It can be accessed with `store.get_state()`.

```GDScript
{
    'game': {
        'paused': false
    }
    'players': {
        'player1': {
            'id': 'player1',
            'name': 'Jane',
            'position_x': 0,
            'position_y': 0,
            'moving': true
        }
    },
}
```

### Actions

The way to change the state is to create an _action_, an `Dictionary` object describing the changes you want to make, and _dispatch_ it to the store. To dispatch an action, you use `store.dispatch()`.

Actions must have a `type` property, and are deployed with an _action creator_, a function which returns the action.

```GDScript
func game_update_paused(paused):
    return {
        'type': 'GAME_UPDATE_PAUSED',
        'paused': paused
    }
```

To dispatch an action to our store, use `store.dispatch()` from a non-singleton script. This is due to singletons being processed last in the [tree order](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scene_tree.html#tree-order).

```GDScript
onready var actions := get_node('/root/actions')
onready var reducers := get_node('/root/reducers')
onready var store := get_node('/root/store')

func _ready():
    store.create([
        {'name': 'game', 'instance': reducers},
        {'name': 'players', 'instance': reducers}
    ])

    # game_update_paused() is called, an action creator that returns
    # an action dictionary that can be dispatched.
    var new_action = actions.game_update_paused(true)
    store.dispatch(new_action)
```

### Reducers

Reducers consume dispatched actions and create a new state object to be applied to the store. Reducers are pure functions that take 2 parameters: the last known state and an action.

When you create a reducer, it is important that it is a pure function. Specifically:

* The state is _read-only_, so the reducer must construct a new `state` object or return the unchanged `state` argument.
* The return value must be the same given the same arguments. Impure functions cannot be used within a reducer.

```GDScript
onready var store := get_node('/root/store')

func game(state, action):
    if action['type'] == 'GAME_UPDATE_PAUSED':
        var new_state = state.duplicate()
        new_state['paused'] = action['paused']
        return new_state
    
    return state
```

### Subscribers

Subscriber functions are called whenever the state is changed. These are useful for listening to changes to the global state from any file in your game. 

Functions can be subscribed to the state by calling `store.subscribe()`, passing the node where the function is located, and the name of the function. The subscribed function only begins listening to state changes after store.subscribe() is called, so be aware of the [tree order](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scene_tree.html#tree-order) when making state changes when the scene tree is first initialized.

The subscribe() function returns a `Closure` which can be used to unsubscribe the same function. To do so, you can call `call_funcv()` on the return value of subscribe(). You can also call `store.unsubscribe()` directly with the node where the function is located and the function name as arguments.

```GDScript
func _ready():
    # This will subscribe print_pause_state() to the store.
    var unsubscribe = store.subscribe(self, "state_updated")

    # This will unsubscribe print_pause_state() from the store.
    unsubscribe.call_funcv()

func state_updated():
    var new_state = store.get_state()
    print(new_state)
```

#### Subscribe Enhancers

The base subscribe method notifies listeners when the store updates. It does not specify which part of the store it listens to. Subscribe Enhancers can be used to specify what updates the subscriber function listens to. Godux provides the `Watch` subscribe enhancer. This enhancer lets you know what changed with an `object_path` argument. To use this class, autoload `Watch.gd`.

```GDScript
onready var watch := get_node('/root/watch')

func _ready():
    # Pass the object path as the third argument. The first key in
    # the object path is the reducer, and each additional key
    # is accessed with dot notation.
    watch.subscribe(self, 'coins_updated', ['game.coins'])

    # This will unsubscribe print_pause_state() from the store.
    unsubscribe.call_funcv()

func coins_updated(params: Dictionary):
    var path = params['path']
    if path != 'game.coins':
        return

    var prev_value = params['prev_value']
    var next_value = params['next_value']
    
    print('%s changed from %s to %s', [path, prev_value, next_value])
```

Subscribe Enhancers receive similar arguments to `store.subscribe()`. Additional parameters are passed as a single array. Subscriber functions receive all arguments as a `Dictionary` with argument names as the keys of the dictionary.

## API

### store.get_state()

No parameters.

Returns: Dictionary containing entire state.

### store.create(reducers, [callbacks])

Parameter | Required | Description | Example
--- | --- | --- | ---
`reducers` | Yes | An array of dictionaries, each with `name` and `instance` keys. | `[{ 'name': 'function_name', 'instance': obj }]`
`callbacks` | No | An array of dictionaries, each with `name` and `instance` keys. | `[{ 'name': 'function_name', 'instance': obj }]`

Returns: Nothing.

### store.dispatch(action)

Parameter | Required | Description | Example
--- | --- | --- | ---
`action` | Yes | A dictionary containing `type` key. | `{ 'type': 'ACTION_TYPE' }`

Returns: Nothing

### store.subscribe(target, method)

Parameter | Required | Description | Example
--- | --- | --- | ---
`target` | Yes | Object containing the callback function. | `self`
`method` | Yes | String of the callback function name. | `'callback_function'`

Returns: Closure object. Calling `call_funcv()` on this object will unsubscribe the subscribed method.

### store.unsubscribe(target, method)

Parameter | Required | Description | Example
--- | --- | --- | ---
`target` | Yes | Object containing the callback function. | `self`
`method` | Yes | String of the callback function name. | `'callback_function'`

Returns: Nothing

## Contributors

* **Nathaniel Adams** <<nathaniel.adams@berkeley.edu>>
* **Kenny Au** - *original author* - <<glumpyfish@gmail.com>>

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.
