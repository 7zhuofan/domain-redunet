from flask import Flask, render_template, request, redirect, url_for, session, flash
from flask_mysqldb import MySQL
import MySQLdb.cursors
from werkzeug.security import generate_password_hash, check_password_hash
import os
import re
from datetime import timedelta

app = Flask(__name__)
# 使用随机生成的密钥，提高安全性
app.secret_key = os.urandom(24)
# 设置会话过期时间
app.permanent_session_lifetime = timedelta(hours=2)

# 配置数据库
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = '123456'
app.config['MYSQL_DB'] = 'er_database'
app.config['MYSQL_CURSORCLASS'] = 'DictCursor'  # 直接设置cursor类型

mysql = MySQL(app)

# 检查数据库连接是否成功
def get_cursor():
    try:
        cursor = mysql.connection.cursor()
        return cursor
    except Exception as e:
        raise Exception(f"数据库连接失败: {str(e)}")

# 首页：登录页面
@app.route('/')
def login():
    # 如果用户已经登录，直接跳转到主页
    if 'logged_in' in session:
        return redirect(url_for('home', username=session['username']))
    return render_template('login.html')

# 登录验证
@app.route('/login', methods=['POST'])
def do_login():
    # 设置永久会话
    session.permanent = True
    
    username = request.form['username']
    password = request.form['password']
    remember_me = 'remember-me' in request.form
    
    if not username or not password:
        flash('请输入用户名和密码', 'danger')
        return render_template('login.html', error='请输入用户名和密码')
    
    try:
        cursor = get_cursor()
        cursor.execute('SELECT * FROM Users WHERE username = %s', (username,))
        user = cursor.fetchone()
        
        if user:
            # 检查密码 - 注意：未来应改为使用加密密码
            if user['password'] == password:  # 应改为 check_password_hash()
                session['logged_in'] = True
                session['username'] = username
                session['user_id'] = user['user_id']
                
                # 如果选择"记住我"，延长会话时间
                if remember_me:
                    session.permanent = True
                    app.permanent_session_lifetime = timedelta(days=30)
                
                return redirect(url_for('home', username=username))
            else:
                flash('密码错误', 'danger')
        else:
            flash('用户名不存在', 'danger')
    
    except Exception as e:
        flash(f'系统错误: {str(e)}', 'danger')
        return render_template('login.html', error=f"数据库错误: {str(e)}")

    return render_template('login.html', error="用户名或密码错误")

# 主界面
@app.route('/home/<username>')
def home(username):
    if 'logged_in' not in session:
        flash('请先登录', 'warning')
        return redirect(url_for('login'))
    
    # 确认URL中的用户名与会话中的用户名一致，防止未授权访问
    if username != session['username']:
        flash('无权访问此页面', 'danger')
        return redirect(url_for('home', username=session['username']))
        
    return render_template('home.html', username=username)

# 查询用户
# 查询用户
@app.route('/view_users')
def view_users():
    if 'logged_in' not in session:
        flash('请先登录', 'warning')
        return redirect(url_for('login'))

    search_query = request.args.get('search', '').strip()  # 从URL获取搜索条件
    role_filter = request.args.get('role', '').strip()  # 如果后续你加上角色字段

    try:
        cursor = get_cursor()
        if search_query:
            # 按用户名或ID搜索（模糊匹配）
            cursor.execute(
                "SELECT * FROM Users WHERE username LIKE %s OR user_id LIKE %s",
                (f'%{search_query}%', f'%{search_query}%')
            )
        else:
            cursor.execute("SELECT * FROM Users")  # 没有查询条件时返回所有用户
        users = cursor.fetchall()
        return render_template('view_users.html', users=users, search_query=search_query)
    except Exception as e:
        flash(f'查询用户列表失败: {str(e)}', 'danger')
        return redirect(url_for('home', username=session['username']))



# 添加用户 - 使用存储过程
@app.route('/add_user', methods=['GET', 'POST'])
def add_user():
    if request.method == 'POST':
        username = request.form['username']
        gender = request.form['gender']
        career_experience = request.form['career_experience']
        education_experience = request.form['education_experience']
        password = request.form['password']
        
        # 表单验证
        if not all([username, gender, career_experience, education_experience, password]):
            flash('所有字段都为必填项', 'danger')
            return render_template('add_user.html')
            
        if len(password) < 6:
            flash('密码长度需至少6个字符', 'danger')
            return render_template('add_user.html')
        
        try:
            cursor = db.cursor()
            cursor.callproc('sp_add_user', (username, gender, career, education, password))
            db.commit()

            
            flash('用户添加成功', 'success')

            return redirect('/view_users')

        except Exception as e:
            # 回滚事务
            mysql.connection.rollback()
            flash(f'添加用户失败: {str(e)}', 'danger')
            return render_template('add_user.html')

    return render_template('add_user.html')



# 删除用户
@app.route('/delete_user/<int:user_id>')
def delete_user(user_id):
    if 'logged_in' not in session:
        flash('请先登录', 'warning')
        return redirect(url_for('login'))
    
    # 防止删除自己的账户
    if int(session['user_id']) == user_id:
        flash('不能删除当前登录的用户账户', 'danger')
        return redirect(url_for('view_users'))

    try:
        cursor = get_cursor()
        cursor.execute('DELETE FROM Users WHERE user_id = %s', [user_id])
        mysql.connection.commit()
        flash('用户删除成功', 'success')
    except Exception as e:
        flash(f'删除用户失败: {str(e)}', 'danger')

    return redirect(url_for('view_users'))

# 编辑用户信息
@app.route('/edit_user/<int:user_id>', methods=['GET', 'POST'])
def edit_user(user_id):
    if 'logged_in' not in session:
        flash('请先登录', 'warning')
        return redirect(url_for('login'))

    try:
        cursor = get_cursor()
        cursor.execute('SELECT * FROM Users WHERE user_id = %s', (user_id,))
        user = cursor.fetchone()
        
        if not user:
            flash('用户不存在', 'danger')
            return redirect(url_for('view_users'))

        if request.method == 'POST':
            username = request.form['username']
            gender = request.form['gender']
            career_experience = request.form['career_experience']
            education_experience = request.form['education_experience']
            password = request.form['password']
            
            # 表单验证
            if not all([username, gender, career_experience, education_experience, password]):
                flash('所有字段都为必填项', 'danger')
                return render_template('edit_user.html', user=user)
                
            if len(password) < 6:
                flash('密码长度需至少6个字符', 'danger')
                return render_template('edit_user.html', user=user)
            
            # 如果修改了用户名，检查新用户名是否已存在
            if username != user['username']:
                cursor.execute('SELECT * FROM Users WHERE username = %s AND user_id != %s', (username, user_id))
                existing_user = cursor.fetchone()
                if existing_user:
                    flash('用户名已存在', 'danger')
                    return render_template('edit_user.html', user=user)
            
            # 更新用户信息
            cursor.execute(
                '''UPDATE Users SET username = %s, gender = %s, career_experience = %s, education_experience = %s, password = %s WHERE user_id = %s''',
                (username, gender, career_experience, education_experience, password, user_id)
            )
            mysql.connection.commit()
            
            # 如果修改的是当前用户，更新会话信息
            if int(session['user_id']) == user_id:
                session['username'] = username
            
            flash('用户信息已更新', 'success')
            return redirect(url_for('view_users'))

    except Exception as e:
        flash(f'修改用户信息时出错: {str(e)}', 'danger')
        return redirect(url_for('view_users'))

    return render_template('edit_user.html', user=user)

# 登出
@app.route('/logout')
def logout():
    session.clear()
    flash('您已成功退出登录', 'info')
    return redirect(url_for('login'))

# 错误处理
@app.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_server_error(e):
    return render_template('500.html'), 500

if __name__ == '__main__':
    app.run(debug=True)