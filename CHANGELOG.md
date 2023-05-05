## 0.3.2

- Handle Emitter.stream error better. 

## 0.3.1

- Fix a build performance issue. 

## 0.3.0

- Change watcher build mechanism to improve performance. 
- [Breaking] Deprecate group (.arg). See #21 for detail.

## 0.2.2

- DefaultCreatorObserver now has a few configs to control what to log.
- DefaultCreatorObserver is default to disabled in release mode for better performance.

## 0.2.1

- Use throwWithStackTrace for better debug log.

## 0.2.0

- [Breaking] Group creator name now takes arguments.

Before:
```
final tabCreator = Creator.arg1<Tab, String>((ref, userId) => 'instagram', 
    name: 'tab');
```
After:
```
final tabCreator = Creator.arg1<Tab, String>((ref, userId) => 'instagram',
    name: (userId) => 'tab_$userId');
```

- [Breaking] ref.set and ref.update now only work for Creator. Use ref.emit to set Emitter.

Before:
```
ref.set(someEmitter, Future.value(someNewValue));
```
After:
```
ref.emit(someEmitter, someNewValue);
```

## 0.1.10

- Improve error logs. 

## 0.1.9

- Add ref.emit to set emitter state directly. 

## 0.1.8

- Fix an issue when null is the first emitted value. 
- Add onDispose to observer. It defaults to do nothing though.

## 0.1.7

- Fix a minor issue about reducer's default name.
- Documentation improvements. 

## 0.1.6

- Add more extension methods. 

## 0.1.5

- Ref.read should not dispose creators with keepAlive set. 

## 0.1.4

- Add Ref.readSelf so creator can have memory. 

## 0.1.3

- Allow Creator to set its dependency. 

## 0.1.2

- Fix an issue related to defining creator as local variable. 

## 0.1.1

- Use creator_core since package name flutter_creator is not available. 

## 0.1.0

- Initial version.
