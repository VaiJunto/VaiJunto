/// Versão do app exibida no rodapé das telas de autenticação.
///
/// REGRA DO PROJETO: toda alteração que exija recompilar (Dart, Gradle, assets,
/// nativo) incrementa o último número. Assim dá para bater o olho no rodapé e
/// saber se o build instalado no device já tem a mudança — sem isso, testar em
/// celular vira adivinhação.
///
/// Formato `major.minor.patch.build`, espelhado no `version:` do pubspec.yaml
/// como `major.minor.patch+build`. Os dois precisam andar juntos.
const String kAppVersion = '1.17.0.2';

/// Revisao injetada pelo build de producao para identificar exatamente qual
/// commit esta rodando. Builds locais exibem `local`.
const String kBuildRevision = String.fromEnvironment(
  'BUILD_REVISION',
  defaultValue: 'local',
);

String get kBuildRevisionShort =>
    kBuildRevision.length > 7 ? kBuildRevision.substring(0, 7) : kBuildRevision;

String get kBuildLabel => 'v$kAppVersion • $kBuildRevisionShort';
