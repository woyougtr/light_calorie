import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../utils/toast.dart';
import 'main_app.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }
  
  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
    _confirmPasswordController.clear();
  }
  
  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    // 表单验证
    if (email.isEmpty) {
      _showMsg('请输入邮箱地址');
      _emailFocus.requestFocus();
      return;
    }
    
    if (!_isValidEmail(email)) {
      _showMsg('请输入有效的邮箱地址');
      _emailFocus.requestFocus();
      return;
    }
    
    if (password.isEmpty) {
      _showMsg('请输入密码');
      _passwordFocus.requestFocus();
      return;
    }
    
    if (password.length < 6) {
      _showMsg('密码长度不能少于6位');
      _passwordFocus.requestFocus();
      return;
    }
    
    if (!_isLogin) {
      if (confirmPassword.isEmpty) {
        _showMsg('请确认密码');
        _confirmPasswordFocus.requestFocus();
        return;
      }
      if (password != confirmPassword) {
        _showMsg('两次输入的密码不一致');
        _confirmPasswordController.clear();
        _confirmPasswordFocus.requestFocus();
        return;
      }
    }
    
    // 隐藏键盘
    FocusScope.of(context).unfocus();
    
    setState(() => _isLoading = true);
    
    try {
      AppUser? user;
      String? errMsg;
      
      if (_isLogin) {
        // 登录
        (user, errMsg) = await SupabaseService.signIn(email, password);
        if (user == null) {
          _showMsg(errMsg ?? '登录失败，请稍后重试');
        } else if (mounted) {
          _showMsg('登录成功！');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MainApp(user: user!)),
            );
          }
        }
      } else {
        // 注册
        (user, errMsg) = await SupabaseService.signUp(email, password);
        if (user == null) {
          _showMsg(errMsg ?? '注册失败，请稍后重试');
          // 如果是需要邮箱确认的情况，提示后切换到登录模式
          if (errMsg?.contains('邮箱') == true && errMsg?.contains('确认') == true) {
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              setState(() => _isLogin = true);
              _passwordController.clear();
            }
          }
        } else if (mounted) {
          _showMsg('注册成功！');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MainApp(user: user!)),
            );
          }
        }
      }
    } catch (e) {
      _showMsg('操作出现异常，请稍后重试');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
  
  void _showMsg(String msg) {
    Toast.show(context, msg);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.background,
              AppColors.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Logo 区域
                      _buildLogo(),
                      const SizedBox(height: 48),
                      // 标题
                      _buildTitle(),
                      const SizedBox(height: 48),
                      // 表单卡片
                      _buildFormCard(),
                      const SizedBox(height: 24),
                      // 切换登录/注册
                      _buildToggleButton(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '轻',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          _isLogin ? '欢迎回来' : '创建账号',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? '登录以继续记录你的健康旅程' : '开始你的轻卡健康生活',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.lightText,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 邮箱输入框
          _buildInputField(
            controller: _emailController,
            focusNode: _emailFocus,
            label: '邮箱地址',
            hint: 'example@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: () => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 20),
          // 密码输入框
          _buildInputField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: '密码',
            hint: '请输入密码',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
            onSubmitted: () {
              if (_isLogin) {
                _submit();
              } else {
                _confirmPasswordFocus.requestFocus();
              }
            },
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.lightText,
                size: 20,
              ),
            ),
          ),
          // 确认密码（仅注册时显示）
          if (!_isLogin) ...[
            const SizedBox(height: 20),
            AnimatedOpacity(
              opacity: _isLogin ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: _buildInputField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocus,
                label: '确认密码',
                hint: '请再次输入密码',
                icon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                onSubmitted: () => _submit(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.lightText,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          // 提交按钮
          _buildSubmitButton(),
        ],
      ),
    );
  }
  
  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    VoidCallback? onSubmitted,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focusNode.hasFocus ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onSubmitted: (_) => onSubmitted?.call(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.lightText,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: focusNode.hasFocus ? AppColors.primary : AppColors.lightText,
                size: 20,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.darkText,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSubmitButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _submit,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isLogin ? '登 录' : '注 册',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? '还没有账号？' : '已有账号？',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.lightText,
          ),
        ),
        TextButton(
          onPressed: _toggleMode,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            _isLogin ? '立即注册' : '去登录',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}