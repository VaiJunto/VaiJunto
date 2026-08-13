/// Regras de validação compartilhadas entre as telas de login e cadastro.
library;

/// Domínios institucionais aceitos para criar conta no VaiJunto.
const institutionalDomains = <String>[
  'aluno.cps.sp.gov.br',
  'fatec.sp.gov.br',
];

/// Uma regra de senha individual, para exibir como checklist na UI.
class PasswordRule {
  const PasswordRule(this.label, this._test);

  final String label;
  final bool Function(String) _test;

  bool isSatisfiedBy(String password) => _test(password);
}

const passwordRules = <PasswordRule>[
  PasswordRule('Pelo menos 8 caracteres', _minLength),
  PasswordRule('Uma letra maiúscula', _hasUppercase),
  PasswordRule('Uma letra minúscula', _hasLowercase),
  PasswordRule('Um número', _hasDigit),
];

bool _minLength(String p) => p.length >= 8;
bool _hasUppercase(String p) => p.contains(RegExp(r'[A-Z]'));
bool _hasLowercase(String p) => p.contains(RegExp(r'[a-z]'));
bool _hasDigit(String p) => p.contains(RegExp(r'[0-9]'));

/// Valida o e-mail institucional. Retorna `null` quando válido.
String? validateInstitutionalEmail(String? value) {
  final email = value?.trim().toLowerCase() ?? '';
  if (email.isEmpty) return 'Informe seu e-mail institucional';

  if (!RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(email)) {
    return 'E-mail inválido';
  }

  final domain = email.split('@').last;
  if (!institutionalDomains.contains(domain)) {
    return 'Use seu e-mail @aluno.cps.sp.gov.br ou @fatec.sp.gov.br';
  }

  return null;
}

/// Valida a senha contra todas as [passwordRules]. Retorna `null` quando válida.
String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Informe sua senha';

  final unmet = passwordRules.where((r) => !r.isSatisfiedBy(password));
  if (unmet.isNotEmpty) {
    return 'A senha não atende aos requisitos';
  }

  return null;
}
