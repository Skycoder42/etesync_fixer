import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

base class _ICalNamedElement {
  String _name;

  @nonVirtual
  String get name => _name;

  @nonVirtual
  set name(String name) => _name = name.toUpperCase();

  @protected
  _ICalNamedElement(String name) : _name = name.toUpperCase();
}

mixin _ICalBlockCollection {
  List<ICalBlock> get _blocks;

  ICalBlock? getBlock(String name) => getBlocks(name).singleOrNull;

  List<ICalBlock> getBlocks(String name) {
    final upperName = name.toUpperCase();
    return _blocks.where((p) => p.name == upperName).toList();
  }

  void add(ICalBlock block) => _blocks.add(block);

  void addAll(Iterable<ICalBlock> blocks) => _blocks.addAll(blocks);

  bool remove(ICalBlock block) => _blocks.remove(block);

  void removeAll(Iterable<ICalBlock> blocks) => blocks.forEach(remove);

  Iterable<ICalBlock> findBlocks(String name) sync* {
    final upperName = name.toUpperCase();
    for (final block in _blocks) {
      if (block.name == upperName) {
        yield block;
      }
      yield* block.findBlocks(upperName);
    }
  }
}

class ICalendar with IterableMixin<ICalBlock>, _ICalBlockCollection {
  @override
  final List<ICalBlock> _blocks;

  ICalendar(Iterable<ICalBlock>? blocks) : _blocks = blocks?.toList() ?? [];

  @override
  Iterator<ICalBlock> get iterator => _blocks.iterator;
}

sealed class ICalComponent extends _ICalNamedElement {
  @protected
  ICalComponent(super.name);
}

final class ICalBlock extends ICalComponent
    with IterableMixin<ICalComponent>, _ICalBlockCollection {
  final List<ICalProperty> _properties;

  @override
  final List<ICalBlock> _blocks;

  ICalBlock(
    super.name, {
    Iterable<ICalProperty>? properties,
    Iterable<ICalBlock>? blocks,
  })  : _properties = properties?.toList() ?? [],
        _blocks = blocks?.toList() ?? [];

  ICalProperty? getProperty(String name) => getProperties(name).singleOrNull;

  List<ICalProperty> getProperties(String name) {
    final upperName = name.toUpperCase();
    return _properties.where((p) => p.name == upperName).toList();
  }

  @override
  // ignore: avoid_renaming_method_parameters
  void add(ICalComponent component) {
    switch (component) {
      case final ICalProperty property:
        _properties.add(property);
      case final ICalBlock block:
        super.add(block);
    }
  }

  @override
  // ignore: avoid_renaming_method_parameters
  void addAll(Iterable<ICalComponent> components) => components.forEach(add);

  @override
  // ignore: avoid_renaming_method_parameters
  bool remove(ICalComponent component) => switch (component) {
        final ICalProperty property => _properties.remove(property),
        final ICalBlock block => super.remove(block),
      };

  @override
  // ignore: avoid_renaming_method_parameters
  void removeAll(Iterable<ICalComponent> components) =>
      components.forEach(remove);

  @override
  Iterator<ICalComponent> get iterator =>
      _properties.cast<ICalComponent>().followedBy(_blocks).iterator;
}

final class ICalProperty extends ICalComponent
    with IterableMixin<ICalParameter> {
  String value;

  final List<ICalParameter> _parameters;

  ICalProperty(
    super.name,
    this.value, {
    Iterable<ICalParameter>? parameters,
  }) : _parameters = parameters?.toList() ?? [];

  ICalParameter? getParameter(String name) => getParameters(name).singleOrNull;

  List<ICalParameter> getParameters(String name) {
    final upperName = name.toUpperCase();
    return _parameters.where((p) => p.name == upperName).toList();
  }

  void add(ICalParameter parameter) => _parameters.add(parameter);

  void addAll(Iterable<ICalParameter> parameters) =>
      _parameters.addAll(parameters);

  bool remove(ICalParameter parameter) => _parameters.remove(parameter);

  void removeAll(Iterable<ICalParameter> parameters) =>
      parameters.forEach(remove);

  @override
  Iterator<ICalParameter> get iterator => _parameters.iterator;
}

final class ICalParameter extends _ICalNamedElement {
  String value;

  ICalParameter(super.name, this.value);
}
