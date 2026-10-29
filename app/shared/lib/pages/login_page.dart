// lib/pages/login_page.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../services/api.dart'; // ← novo import

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  /// Cria o objeto de estado mutavel que controlara esta tela de login.
  State<LoginPage> createState() => _LoginPageState();
}

// O State guarda tudo que pode mudar enquanto esta tela esta aberta:
// textos digitados, carregamento, visibilidade da senha e animacoes.
class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _apiService = ApiService(); // ← instância do service
  bool _obscureSenha = true;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  /// Configura e inicia as animacoes assim que a tela entra na arvore de widgets.
  void initState() {
    super.initState();
    // O controller determina a duracao; fade e slide descrevem como a tela aparece.
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  /// Libera animacoes e campos de texto para evitar consumo de memoria apos sair da tela.
  void dispose() {
    // Controllers ocupam recursos. A tela deve libera-los quando for removida.
    _animController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // ─── Método de login integrado com ApiService ────────────────────────────
  /// Valida o formulario, chama a API e abre sugestoes quando o login funciona.
  Future<void> _handleLogin() async {
    // Se algum validador do formulario falhar, a requisicao nem e enviada.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // `await` pausa somente esta funcao ate a API responder; a interface continua ativa.
      await _apiService.login(
        _emailController.text.trim(),
        _senhaController.text,
      );

      // Depois de um await, mounted confirma que a tela ainda existe antes de usar context.
      if (mounted) {
        context.go(AppRouter.sugestoes);
      }
    } on Exception catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Exibe erro em SnackBar estilizado ───────────────────────────────────
  /// Exibe uma mensagem temporaria de erro na parte inferior da tela.
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

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  /// Monta a estrutura completa e combina cabecalho, formulario e botoes.
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: kIsWeb ? 816 : 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _buildLoginPanel(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 48),
                        _buildForm(),
                        const SizedBox(height: 24),
                        _buildLoginButton(),
                        const SizedBox(height: 20),
                        _buildRegisterLink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPanel(Widget child) {
    if (!kIsWeb) return child;

    final compact = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 56,
        vertical: compact ? 36 : 80,
      ),
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 464),
          child: child,
        ),
      ),
    );
  }

  /// Monta o logotipo, titulo e texto introdutorio da pagina.
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
            Icons.lock_rounded,
            color: AppTheme.accent,
            size: 36,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Bem-vindo de volta',
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
          'Faça login para continuar',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  /// Monta os campos de e-mail e senha e suas regras de validacao.
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Informe o e-mail';

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _senhaController,
            obscureText: _obscureSenha,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Senha',
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
              if (value == null || value.isEmpty) return 'Informe a senha';
              if (value.length < 6) {
                return 'Senha deve ter pelo menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight),
        ],
      ),
    );
  }

  /// Monta o botao de entrar, mostrando progresso e bloqueando cliques durante o envio.
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text('Entrar'),
      ),
    );
  }

  /// Monta o atalho que leva quem ainda nao possui conta para o cadastro.
  Widget _buildRegisterLink() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Não tem uma conta? ',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        TextButton(
          onPressed: () => context.go(AppRouter.register),
          child: const Text('Cadastre-se'),
        ),
      ],
    );
  }
}
