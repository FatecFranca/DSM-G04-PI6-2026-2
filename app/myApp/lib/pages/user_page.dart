import '../components/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../services/api.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  /// Cria o estado que carregara e permitira editar os dados do perfil.
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _apiService = ApiService();
  bool _obscureSenha = true;
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  /// Inicia o carregamento do usuario assim que a tela e aberta.
  void initState() {
    super.initState();
    _loadUsuario();
  }

  /// Consulta a API e preenche os campos do formulario com os dados atuais.
  Future<void> _loadUsuario() async {
    try {
      final data = await _apiService.getUsuario();
      if (mounted) {
        _nomeController.text = data['nome'] as String? ?? '';
        _emailController.text = data['email'] as String? ?? '';
      }
    } on Exception catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  /// Libera os controllers dos campos quando a pagina for removida.
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  /// Valida e envia somente os dados alterados do perfil para a API.
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (nome.isEmpty && email.isEmpty && senha.isEmpty) {
      _showErrorSnackBar('Preencha ao menos um campo para atualizar.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.updateUsuario(
        nome: nome.isEmpty ? null : nome,
        email: email.isEmpty ? null : email,
        senha: senha.isEmpty ? null : senha,
      );
      if (mounted) {
        _showSuccessSnackBar('Dados atualizados com sucesso!');
        _senhaController.clear();
      }
    } on Exception catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Exibe uma SnackBar vermelha com uma mensagem de falha.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Exibe uma SnackBar verde confirmando uma operacao bem-sucedida.
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  /// Monta a tela e alterna entre carregamento e conteudo do perfil.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go(AppRouter.sugestoes),
        ),
      ),
      body: SafeArea(
        child: _isLoadingData
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildForm(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 16),
                    _buildLogoutButton(),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 4),
    );
  }

  /// Limpa a sessao local e navega de volta para o login.
  Future<void> _handleLogout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.secondary,
        title: const Text(
          'Sair da conta?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Tem certeza que deseja encerrar a sessão?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await ApiService.logout();
    if (!mounted) return;
    context.go(AppRouter.login);
  }

  /// Monta o botao visual que solicita a saida da conta.
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.accent,
          side: const BorderSide(color: AppTheme.accent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sair da conta'),
      ),
    );
  }

  /// Monta o cabecalho visual da area de perfil.
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppTheme.accent,
            size: 36,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Editar Perfil',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Preencha apenas os campos que deseja alterar',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  /// Monta os campos editaveis e suas validacoes.
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nomeController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Nome',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  value.trim().length < 3) {
                return 'Nome deve ter pelo menos 3 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                  return 'E-mail inválido';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _senhaController,
            obscureText: _obscureSenha,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Nova senha',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSenha
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
              ),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length < 6) {
                return 'Senha deve ter pelo menos 6 caracteres';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// Monta o botao de salvar e mostra progresso durante a requisicao.
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text('Salvar alterações'),
      ),
    );
  }

  /// Monta a barra inferior e navega conforme o item escolhido.
  Widget _buildBottomNav(BuildContext context, int currentIndex) =>
      AppBottomNav(indice: currentIndex);
}
// Tela de perfil: carrega os dados do usuario e permite alterar ou excluir a conta.
