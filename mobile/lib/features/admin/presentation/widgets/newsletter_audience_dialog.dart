import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Seletor de destinatários da newsletter.
///
/// Os filtros de grupo (perfil, vínculo, curso, tag) se combinam por **E** —
/// "professores E do curso X" — e as pessoas escolhidas na busca entram por
/// **OU**, sempre somadas. "Todos" ignora o resto. A mesma semântica está no
/// backend, em `NewsletterAudienceService`.
Future<Map<String, dynamic>?> showNewsletterAudienceDialog({
  required BuildContext context,
  required Dio dio,
  required List<dynamic> tags,
  required Map<String, dynamic> audience,
}) =>
    showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) =>
            _AudienceDialog(dio: dio, tags: tags, audience: audience));

/// Resumo legível para o botão do compositor.
String describeAudience(Map<String, dynamic> audience, List<dynamic> tags) {
  if (audience['everyone'] == true) return 'Todo mundo';
  final parts = <String>[];
  final profiles = List<String>.from(audience['profileTypes'] ?? const []);
  final affiliations = List<String>.from(audience['affiliations'] ?? const []);
  final courses = List<String>.from(audience['courses'] ?? const []);
  final tagIds = List<String>.from(audience['tagIds'] ?? const []);
  final userIds = List<String>.from(audience['userIds'] ?? const []);
  final roles = List<String>.from(audience['adminRoles'] ?? const []);
  if (profiles.isNotEmpty) parts.add(profiles.map(profileLabel).join(', '));
  if (affiliations.isNotEmpty) parts.add(affiliations.map(affiliationLabel).join(', '));
  if (courses.isNotEmpty) {
    parts.add(courses.length == 1 ? courses.first : '${courses.length} cursos');
  }
  if (tagIds.isNotEmpty) {
    final names = tags
        .where((tag) => tagIds.contains(tag['id'].toString()))
        .map((tag) => tag['name'].toString());
    parts.add(names.isEmpty ? '${tagIds.length} tags' : names.join(', '));
  }
  if (userIds.isNotEmpty) {
    parts.add('${userIds.length} ${userIds.length == 1 ? 'pessoa' : 'pessoas'}');
  }
  if (roles.isNotEmpty) parts.add('equipe: ${roles.map(roleLabel).join(', ')}');
  return parts.isEmpty ? 'Ninguém escolhido ainda' : parts.join(' • ');
}

String profileLabel(String value) => switch (value) {
      'PASSENGER' => 'Passageiros',
      'VAN_DRIVER' => 'Motoristas de van',
      _ => 'Motoristas de carona',
    };

String affiliationLabel(String value) => switch (value) {
      'STUDENT' => 'Alunos',
      'PROFESSOR' => 'Professores',
      _ => 'Servidores',
    };

String roleLabel(String value) => switch (value) {
      'SUPER_ADMIN' => 'Super admin',
      'ADMIN' => 'Admin',
      _ => 'Moderação',
    };

class _AudienceDialog extends StatefulWidget {
  const _AudienceDialog({required this.dio, required this.tags, required this.audience});
  final Dio dio;
  final List<dynamic> tags;
  final Map<String, dynamic> audience;

  @override
  State<_AudienceDialog> createState() => _AudienceDialogState();
}

class _AudienceDialogState extends State<_AudienceDialog> {
  late Map<String, dynamic> _audience;
  final _courseSearch = TextEditingController();
  final _peopleSearch = TextEditingController();
  var _courses = <dynamic>[];
  var _people = <dynamic>[];
  Timer? _debounce;
  int? _reach;
  var _loadingReach = false;

  @override
  void initState() {
    super.initState();
    _audience = {
      'everyone': widget.audience['everyone'] ?? false,
      'profileTypes': List<String>.from(widget.audience['profileTypes'] ?? const []),
      'affiliations': List<String>.from(widget.audience['affiliations'] ?? const []),
      'courses': List<String>.from(widget.audience['courses'] ?? const []),
      'tagIds': List<String>.from(widget.audience['tagIds'] ?? const []),
      'userIds': List<String>.from(widget.audience['userIds'] ?? const []),
      'adminRoles': List<String>.from(widget.audience['adminRoles'] ?? const []),
      'userLabels': Map<String, String>.from(widget.audience['userLabels'] ?? const {}),
    };
    _loadCourses('');
    _refreshReach();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _courseSearch.dispose();
    _peopleSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final everyone = _audience['everyone'] == true;
    return AlertDialog(
      title: const Text('DESTINATÁRIOS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5)),
      content: SizedBox(
        width: 640,
        height: 560,
        child: Column(children: [
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Todo mundo',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Ignora os filtros abaixo e envia para toda a comunidade ativa.'),
              value: everyone,
              onChanged: (value) {
                setState(() => _audience['everyone'] = value);
                _refreshReach();
              }),
          const Divider(),
          Expanded(
            child: IgnorePointer(
              ignoring: everyone,
              child: Opacity(
                opacity: everyone ? .4 : 1,
                child: ListView(children: [
                  _section('TIPO DE PERFIL'),
                  _chips('profileTypes',
                      const ['PASSENGER', 'VAN_DRIVER', 'CARPOOL_DRIVER'], profileLabel),
                  _section('VÍNCULO'),
                  _chips('affiliations', const ['STUDENT', 'PROFESSOR', 'STAFF'],
                      affiliationLabel),
                  const SizedBox(height: 4),
                  Text(
                      'O cadastro de vínculo ainda não existe: quem não tiver o campo preenchido não entra por este filtro.',
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                  _section('CURSO'),
                  TextField(
                      controller: _courseSearch,
                      onChanged: _onCourseSearch,
                      decoration: const InputDecoration(
                          isDense: true,
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Buscar curso (aceita erro de digitação)')),
                  const SizedBox(height: 8),
                  ..._courses.map((course) {
                    final name = course['course'].toString();
                    final selected =
                        (_audience['courses'] as List).contains(name);
                    return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: selected,
                        title: Text(name),
                        subtitle: Text('${course['people']} pessoas'),
                        onChanged: (value) {
                          setState(() {
                            final courses = _audience['courses'] as List;
                            value == true ? courses.add(name) : courses.remove(name);
                          });
                          _refreshReach();
                        });
                  }),
                  _section('TAGS'),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.tags.map((tag) {
                        final id = tag['id'].toString();
                        final selected = (_audience['tagIds'] as List).contains(id);
                        return FilterChip(
                            label: Text(tag['name'].toString()),
                            selected: selected,
                            onSelected: (value) {
                              setState(() {
                                final ids = _audience['tagIds'] as List;
                                value ? ids.add(id) : ids.remove(id);
                              });
                              _refreshReach();
                            });
                      }).toList()),
                  _section('PESSOAS ESPECÍFICAS'),
                  TextField(
                      controller: _peopleSearch,
                      onChanged: _onPeopleSearch,
                      decoration: const InputDecoration(
                          isDense: true,
                          prefixIcon: Icon(Icons.person_search),
                          hintText: 'Buscar por nome ou email')),
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_audience['userIds'] as List).map((id) {
                        final labels = _audience['userLabels'] as Map;
                        return InputChip(
                            label: Text(labels[id]?.toString() ?? id.toString()),
                            onDeleted: () {
                              setState(() {
                                (_audience['userIds'] as List).remove(id);
                                labels.remove(id);
                              });
                              _refreshReach();
                            });
                      }).toList()),
                  ..._people.map((person) {
                    final id = person['id'].toString();
                    if ((_audience['userIds'] as List).contains(id)) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(person['fullName']?.toString() ?? ''),
                        subtitle: Text(person['email']?.toString() ?? ''),
                        trailing: const Icon(Icons.add),
                        onTap: () {
                          setState(() {
                            (_audience['userIds'] as List).add(id);
                            (_audience['userLabels'] as Map)[id] =
                                person['fullName']?.toString() ?? id;
                          });
                          _refreshReach();
                        });
                  }),
                ]),
              ),
            ),
          ),
          const Divider(),
          _section('EQUIPE ADMINISTRATIVA'),
          Text(
              'Contas do painel não têm registro de usuário: a newsletter aparece para elas dentro do painel.',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          _chips('adminRoles', const ['SUPER_ADMIN', 'ADMIN', 'MODERATOR'], roleLabel),
        ]),
      ),
      actions: [
        Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
                _loadingReach
                    ? 'Calculando alcance...'
                    : _reach == null
                        ? ''
                        : '$_reach ${_reach == 1 ? 'destinatário' : 'destinatários'}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _audience),
            child: const Text('CONFIRMAR')),
      ],
    );
  }

  Widget _section(String label) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label,
              style: const TextStyle(
                  fontFamily: 'IBMPlexMono', fontSize: 10, fontWeight: FontWeight.w700))));

  Widget _chips(String field, List<String> values, String Function(String) label) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final selected = (_audience[field] as List).contains(value);
        return FilterChip(
            label: Text(label(value)),
            selected: selected,
            onSelected: (checked) {
              setState(() {
                final list = _audience[field] as List;
                checked ? list.add(value) : list.remove(value);
              });
              _refreshReach();
            });
      }).toList());

  void _onCourseSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _loadCourses(value));
  }

  void _onPeopleSearch(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _people = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _loadPeople(value));
  }

  Future<void> _loadCourses(String query) async {
    try {
      final response = await widget.dio.get('/admin/courses',
          queryParameters: query.trim().isEmpty ? null : {'q': query.trim()});
      if (mounted) setState(() => _courses = response.data as List<dynamic>);
    } on DioException {
      if (mounted) setState(() => _courses = []);
    }
  }

  Future<void> _loadPeople(String query) async {
    try {
      final response =
          await widget.dio.get('/admin/search', queryParameters: {'q': query.trim()});
      if (mounted) setState(() => _people = response.data as List<dynamic>);
    } on DioException {
      if (mounted) setState(() => _people = []);
    }
  }

  Future<void> _refreshReach() async {
    setState(() => _loadingReach = true);
    try {
      final payload = Map<String, dynamic>.from(_audience)..remove('userLabels');
      final response =
          await widget.dio.post('/admin/newsletters/audience', data: payload);
      if (!mounted) return;
      setState(() => _reach = (response.data['userCount'] as num).toInt() +
          (response.data['adminCount'] as num).toInt());
    } on DioException {
      if (mounted) setState(() => _reach = null);
    } finally {
      if (mounted) setState(() => _loadingReach = false);
    }
  }
}
