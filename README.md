# WindowsToast

Fires a Windows toast.

## Why

A user command that runs for a while gets left alone: the user will switch to something else, and
when it finally asks a question, nobody notices that the session is sitting there waiting.


## What it looks like

![Windows Toast](WindowsToast.png)

## Usage

```
      ]Tatin.LoadPackages [tatin]aplteam-WindowsToast #
```

The only function `Notify` requirers two argument, "type" and 


## Good behaviour

* It does not make you wait: The notification is started detached; `Notify` returns in
  about 15 ms, so your question is not held up by it.
* It never brings your application down: `Notify` traps its errors: should anything fail, the question is asked anyway
  and `⎕DMX` is saved on `∆NotifyError` for you to look at.
* It does not collide with automation `CommTools` calls the notifier only when a human is
  really asked.


## Documentation

```
      ]ADoc WindowsToast
```

or call `WindowsToast.Help`, which does the same. 

## License

MIT, see [LICENSE](LICENSE).


