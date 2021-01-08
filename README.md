<h1 align="center">
    <img src="icon.png" alt="Godot" height="60"/>
</h1>

<div align="center">
    A state management library written in GDScript inspired by <a href="https://redux.js.org">Redux</a>.
</div>

<div>&nbsp;</div>

Godux helps Godot developers consolidate game state into a single store. Communicating between nodes in your project becomes increasingly difficult the more complex your project becomes. Instead of littering all component nodes with game state, which can be unruly and confusing for larger projects, we can use a single source of information in order to easily access all data in your game from any node.

Using the redux architecture allows for some interesting features:
* Saving and loading saved games becomes trivial.
* Undo/redoing actions.
* Event notifications.
* Quest tracking.

## Installation

* Autoload `store.gd` from "Scene > Project Settings > AutoLoad" so that it is loaded first.
* Attach `main.gd` to a root node, or a node that loads before any of the actions are used.

## Usage

A common implementation is to create and autoload the following scripts:
* `action_types.gd`
* `actions.gd`
* `reducers.gd`

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
func players_update_position(id, position_x, position_y):
    return {
        'type': 'PLAYERS_UPDATE_POSITION',
        'id': id
        'position_x': position_x,
        'position_y': position_y
    }
```

We can then dispatch an action to our store via `store.dispatch()` from a non-singleton script. This is due to singletons being processed last in the [tree order](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scene_tree.html#tree-order).

```GDScript
onready var actions := get_node('/root/actions')
onready var reducers := get_node('/root/reducers')
onready var store := get_node('/root/store')

func _ready():
    store.create([
        {'name': 'game', 'instance': reducers},
        {'name': 'players', 'instance': reducers}
    ])

    # new_action calls players_update_position(), a function we created that returns
    # an action dictionary that we can dispatch.
    var new_action = actions.players_update_position('player1', 5, 10)
    store.dispatch(new_action)
```

### Reducers

Reducers consume dispatched actions and create a new state object to be applied to the store. Reducers are pure functions that take 2 parameters: the last known state and an action.

When you create a reducer, it is important that it is a pure function. Specifically:
* The state is _read-only_, so the reducer must construct a new `state` object or return the unchanged `state` argument.
* The return value must be the same given the same arguments. Impure functions cannot be used within a reducer.

```GDScript
func players(state, action):
    if action['type'] == 'PLAYERS_UPDATE_POSITION':
        var players_state = store.shallow_copy(state[action['id']])
        players_state['position_x'] = action['position_x']
        players_state['position_y'] = action['position_y']

        var new_state = store.shallow_copy(state)
        new_state[action['id']] = player_state
        return new_state
    
    return state
```

### Subscribers

Subscriber functions are called whenever the state is changed. These are useful for listening to changes to the global state from any file in your game. Subscriber functions take the reducer name and the updated state as arguments.

## Example

A good way to start with redux is by planning what your store will look like. The store is a dictionary of dictionaries where the first level keys (`game`, `players`, `gui`, `stats`, `dungeon1`) are reducers. Here is an example that shows some possible ideas:

```GDScript
{
    'game': {
        'paused': false
    }
    'players': {
        'player1': {
            'id': 'player1',
            'name': 'Jane',
            'location_x': 0,
            'location_y': 0,
            'moving': true
        }
    },
    'gui': {
        'loading': false,
    },
    'stats': {
        'timer_start_time': 0,
        'timer_running': false
    }
    'dungeon1': {
        'found_key': true,
        'found_map': false,
        'found_compass': false
    }
}
```

It is best if the data is normalized, or as flat as possible. Often the tree is only 2 or 3 levels deep.

Once you have a basic store schema, you can plan some action types. A common practice is to create constants and make them equal to strings of the same name. The naming scheme tends to be NOUN_VERB.

```GDScript
const GAME_PAUSE = 'GAME_PAUSE'
const GAME_UNPAUSE = 'GAME_UNPAUSE'
const PLAYER_MOVE_START = 'PLAYER_MOVE_START'
const PLAYER_MOVE_UPDATE = 'PLAYER_MOVE_UPDATE'
const PLAYER_MOVE_END = 'PLAYER_MOVE_END'
const TIMER_START = 'TIMER_START'
const TIMER_STOP = 'TIMER_STOP'
```

We then create the actions which allow us to specify what information each action needs.

```GDScript
function game_pause():
    return { 'type': GAME_PAUSE }

function game_unpause():
    return { 'type': GAME_UNPAUSE }

function player_move_start(id):
    return { 'type': PLAYER_MOVE_START, 'id': id }

function player_move_update(id, vect2D):
    return { 'type': PLAYER_MOVE_UPDATE, 'id': id, 'newX': vect2D.x, 'newY': vect2D.y }

function player_move_end(id):
    return { 'type': PLAYER_MOVE_END, 'id': id }

function timer_start(time):
    return { 'type': TIMER_START, 'time': time }

function timer_stop():
    return { 'type': TIMER_STOP }
```

Reducers can now be defined. They receive the previous state (for that particular reducer) and the action. The return value must be either the same state (which should always be the default case), or a completely new dictionary object for the given action. Even if the new state is very similar to the old state, the new state must be a separate copy.  If the state needs to be complex, we can use strategic shallow copies to avoid churn from too much object cloning.

```GDScript
function game(state, action):
    if action['type'] == GAME_PAUSE:
        return {'paused': true}
    return state

function players(state, action):
    if action['type'] == PLAYER_MOVE_START:
        var player_state = store.shallow_copy(state[action['id']])
        player_state['moving'] = true
        var new_state = store.shallow_copy(state)
        new_state[action['id']] = player_state
        return new_state
    if action['type'] == PLAYER_MOVE_UPDATE:
        var player_state = store.shallow_copy(state[action['id']])
        player_state['location_x'] = action['x']
        player_state['location_y'] = action['y']
        var new_state = store.shallow_copy(state)
        new_state[action['id']] = player_state
        return new_state
    if action['type'] == PLAYER_MOVE_END:
        var player_state = store.shallow_copy(state[action['id']])
        player_state['moving'] = false
        var new_state = store.shallow_copy(state)
        new_state[action['id']] = player_state
        return new_state
    return state

function stats(state, action):
    if action['type'] == TIMER_START:
        var new_state = store.shallow_copy(state)
        new_state['timer_start_time'] = action['time']
        new_state['timer_running'] = true
        return new_state
    if action['type'] == TIMER_END:
        var new_state = store.shallow_copy(state)
        new_state['timer_running'] = false
        return new_state
    return state
```
And finally, the action creators can be created throughout your code. They are functions responsible for firing off the actions to the store.
```
function on_pause_button_click():
    var is_paused = store.get()['game']['paused']
    if is_paused:
        store.dispatch(actions.game_unpause())
        store.dispatch(actions.timer_start(OS.get_unix_time()))
    else:
        store.dispatch(actions.game_pause())
        store.dispatch(actions.timer_stop())
```

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

Returns: Nothing

### store.unsubscribe(target, method)

Parameter | Required | Description | Example
--- | --- | --- | ---
`target` | Yes | Object containing the callback function. | `self`
`method` | Yes | String of the callback function name. | `'callback_function'`

Returns: Nothing

### store.shallow_copy(dict)

Parameter | Required | Description | Example
--- | --- | --- | ---
`dict` | Yes | Dictionary to be cloned. | `{ 'key1' : 'value1' }`

Returns: A copy of the dictionary, however only the first level of keys are cloned.

### store.shallow_merge(src_dict, dest_dict)

Parameter | Required | Description | Example
--- | --- | --- | ---
`src_dict` | Yes | Dictionary to merge. | `{ 'key' : 'new_value' }`
`dest_dict` | Yes | Dictionary affected by merge. | `{ 'key' : 'old_value' }`

Returns: Nothing. `dest_dict` is mutated and now has merge changes. Only the first level of keys is copied. Later levels are referenced.

## Authors

* **Nathaniel Adams** <<nathaniel.adams@berkeley.edu>>
* **Kenny Au** - *original author* - <<glumpyfish@gmail.com>>

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.
