import React, { useState, useEffect } from "react";
import axios from "axios";
import { AppBar, Toolbar, Typography, Container, Box, Button, TextField, Card, CardContent, CardActions, Paper, IconButton, Avatar, Divider, Snackbar, Alert, Pagination } from "@mui/material";
import SchoolIcon from '@mui/icons-material/School';
import PersonIcon from '@mui/icons-material/Person';

// APIのベースURL
const API_URL = process.env.REACT_APP_API_URL ? process.env.REACT_APP_API_URL : "/api";
console.log("API_URL:", API_URL);

/**
 * プロフィールページコンポーネント
 * @param {string} username - 現在のユーザー名
 * @param {function} onBack - 戻るボタンがクリックされたときのコールバック
 */
function ProfilePage({ username, onBack }: { username: string; onBack: () => void }) {
  const [profile, setProfile] = useState<any>(null);

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        // 全ユーザーリストから現在のユーザーのプロフィールを検索
        const res = await axios.get(`${API_URL}/admin/users`);
        const user = res.data.find((u: any) => u.username === username);
        setProfile(user || null);
      } catch (error) {
        console.error("プロフィール取得失敗:", error);
      }
    };
    fetchProfile();
  }, [username]);

  return (
    <Container maxWidth="sm" sx={{ mt: 4 }}>
      <Button variant="outlined" onClick={onBack} startIcon={<PersonIcon />}>戻る</Button>
      <Typography variant="h4" sx={{ mt: 2, mb: 2 }}>プロフィール</Typography>
      {profile ? (
        <Card sx={{ borderRadius: 2, boxShadow: 3 }}>
          <CardContent>
            <Box display="flex" alignItems="center" gap={2}>
              <Avatar sx={{ bgcolor: "primary.main", width: 56, height: 56 }}>{profile.username[0]}</Avatar>
              <Box>
                <Typography variant="h6">{profile.username}</Typography>
                <Typography color="text.secondary">氏名: {profile.full_name}</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      ) : (
        <Typography>読み込み中...</Typography>
      )}
    </Container>
  );
}

/**
 * 進捗カード表示コンポーネント
 * @param {any} progress - ユーザーごとの進捗または全ユーザーの進捗リスト
 * @param {any[]} courses - コース情報のリスト
 * @param {any[]} users - ユーザー情報のリスト
 */
function ProgressCards({ progress, courses, users }: { progress: any; courses: any[]; users: any[] }) {
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 15;

  // 進捗データが変更された時にページをリセット
  useEffect(() => {
    setCurrentPage(1);
  }, [progress]);

  // 進捗データがない場合の表示
  if (!progress || (Array.isArray(progress) && (progress.length === 0 || progress.every((p: any) => Object.keys(p).length === 0)))) {
    return <Typography color="text.secondary">受講中のコースはありません。</Typography>;
  }
  // コース情報がまだロードされていない場合の表示
  if (!courses || courses.length === 0) {
    return <Typography color="text.secondary">コース情報取得中...</Typography>;
  }

  // 進捗データを常に配列として扱う
  const progressList = Array.isArray(progress) ? progress : [progress];

  // ページネーション計算
  const totalPages = Math.ceil(progressList.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentProgress = progressList.slice(startIndex, endIndex);

  const handlePageChange = (event: React.ChangeEvent<unknown>, value: number) => {
    setCurrentPage(value);
  };

  return (
    <Box>
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: 'repeat(1, 1fr)', sm: 'repeat(2, 1fr)', md: 'repeat(3, 1fr)' }, gap: 2 }}>
        {currentProgress.map((p: any, idx: number) => {
          // course_idとidの型を揃えて比較してコース情報を取得
          const course = courses.find(c => String(c.id) === String(p.course_id));
          // user_idベースでユーザー検索（idフィールドが存在しない場合の代替手段）
          // まずIDフィールドで検索を試行
          let user = users?.find(u => 
            String(u.id || u.user_id || u.ID || u.Id) === String(p.user_id)
          );
          
          // IDフィールドでの検索に失敗した場合、user_idの位置でユーザーリストから推測
          if (!user && users && users.length > 0 && typeof p.user_id === 'number' && p.user_id > 0 && p.user_id <= users.length) {
            user = users[p.user_id - 1]; // user_id=1なら配列のindex=0
          }

          return (
            <Card key={idx} sx={{ 
              width: '100%', 
              p: 1, 
              borderRadius: 2, 
              boxShadow: 2,
              display: 'flex',
              flexDirection: 'column',
              height: '160px' // 固定の高さを短縮（200px → 160px）
            }}>
              <CardContent sx={{ 
                flexGrow: 1, 
                display: 'flex', 
                flexDirection: 'column', 
                pb: 0.5,
                px: 1.5,
                pt: 1.5,
                height: '100%',
                justifyContent: 'space-between'
              }}>
                {/* 上部セクション：ユーザー名とタイトル */}
                <Box>
                  <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 0.5, height: '1em', fontSize: '0.8rem' }}>
                    {user ? `受講者: ${user.username}` : `受講者: 不明`}
                  </Typography>
                  <Typography variant="h6" sx={{ 
                    mb: 0.5, // マージンを縮小（1 → 0.5）
                    height: '3em', // 高さを少し縮小（3.6em → 3em）
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    display: '-webkit-box',
                    WebkitLineClamp: 2,
                    WebkitBoxOrient: 'vertical',
                    lineHeight: 1.2,
                    fontSize: '1.1rem' // フォントサイズを少し縮小
                  }}>
                    {course ? course.title : `コース名不明 (course_id: ${p.course_id})`}
                  </Typography>
                </Box>
                
                {/* 下部セクション：プログレスバーと更新情報 */}
                <Box>
                  <Box sx={{ bgcolor: '#e0e0e0', borderRadius: 1, height: 12, width: '100%', mb: 0.5 }}>
                    <Box sx={{ bgcolor: p.percent === 100 ? 'success.main' : 'primary.main', width: `${p.percent ?? 0}%`, height: '100%', borderRadius: 1 }} />
                  </Box>
                  <Typography variant="body2" sx={{ mb: 0.5, height: '1.2em', fontSize: '0.85rem' }}>
                    {typeof p.percent === 'undefined' ? '進捗データ不明' : p.percent === 0 ? '未着手' : p.percent === 100 ? '完了' : `${p.percent}% 完了`}
                  </Typography>
                  <Typography variant="caption" color="text.secondary" sx={{ height: '1em', fontSize: '0.75rem' }}>
                    更新: {
                      p.updated_at ? p.updated_at.replace('T', ' ').slice(0, 16) :
                      p.updatedAt ? p.updatedAt.replace('T', ' ').slice(0, 16) :
                      p.update_time ? p.update_time.replace('T', ' ').slice(0, 16) :
                      '-'
                    }
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          );
        })}
      </Box>
      {totalPages > 1 && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 3 }}>
          <Pagination 
            count={totalPages} 
            page={currentPage} 
            onChange={handlePageChange}
            color="primary"
            size="medium"
          />
        </Box>
      )}
      <Typography variant="body2" color="text.secondary" sx={{ mt: 1, textAlign: 'center' }}>
        {progressList.length} 件中 {startIndex + 1}-{Math.min(endIndex, progressList.length)} 件を表示
      </Typography>
    </Box>
  );
}

/**
 * コースカード表示コンポーネント
 * @param {any[]} courses - コース情報のリスト
 * @param {function} onJoin - コース参加ボタンがクリックされたときのコールバック
 * @param {string} username - 現在のユーザー名 (参加ボタンの有効/無効制御用)
 */
function CourseCards({ courses, onJoin, username }: { courses: any[]; onJoin: (courseId: number) => void; username: string }) {
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 15;

  if (!courses || courses.length === 0) {
    return <Typography color="text.secondary">コースデータなし</Typography>;
  }

  // ページネーション計算
  const totalPages = Math.ceil(courses.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentCourses = courses.slice(startIndex, endIndex);

  const handlePageChange = (event: React.ChangeEvent<unknown>, value: number) => {
    setCurrentPage(value);
  };

  return (
    <Box>
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: 'repeat(1, 1fr)', sm: 'repeat(2, 1fr)', md: 'repeat(3, 1fr)' }, gap: 2 }}>
        {currentCourses.map((course: any) => (
          <Card key={course.id} sx={{ 
            width: '100%', 
            p: 1, 
            borderRadius: 2, 
            boxShadow: 2,
            display: 'flex',
            flexDirection: 'column',
            height: '160px' // カードの高さを短縮（200px → 160px）
          }}>
            <CardContent sx={{ 
              flexGrow: 1, 
              display: 'flex', 
              flexDirection: 'column', 
              pb: 0.5,
              px: 1.5,
              pt: 1.5,
              height: '100%',
              justifyContent: 'space-between'
            }}>
              {/* 上部セクション：タイトル */}
              <Box>
                <Typography variant="h6" sx={{ 
                  mb: 0.5, // マージンを縮小（1 → 0.5）
                  height: '3em', // 高さを少し縮小（3.6em → 3em）
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  display: '-webkit-box',
                  WebkitLineClamp: 2,
                  WebkitBoxOrient: 'vertical',
                  lineHeight: 1.2,
                  fontSize: '1.1rem' // フォントサイズを少し縮小
                }}>
                  {course.title}
                </Typography>
              </Box>
              
              {/* 下部セクション：概要 */}
              <Box sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
                <Typography variant="body2" color="text.secondary" sx={{ 
                  flexGrow: 1,
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  display: '-webkit-box',
                  WebkitLineClamp: 2, // 行数を縮小（3 → 2）
                  WebkitBoxOrient: 'vertical',
                  fontSize: '0.85rem', // フォントサイズを少し縮小
                  lineHeight: 1.3
                }}>
                  {course.description || ''}
                </Typography>
              </Box>
            </CardContent>
            <CardActions sx={{ mt: 'auto', justifyContent: 'flex-start', pt: 0, pb: 1, px: 1.5 }}>
              <Button size="small" variant="contained" onClick={() => onJoin(course.id)} disabled={!username} sx={{ borderRadius: 1 }}>参加</Button>
            </CardActions>
          </Card>
        ))}
      </Box>
      {totalPages > 1 && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 3 }}>
          <Pagination 
            count={totalPages} 
            page={currentPage} 
            onChange={handlePageChange}
            color="primary"
            size="medium"
          />
        </Box>
      )}
      <Typography variant="body2" color="text.secondary" sx={{ mt: 1, textAlign: 'center' }}>
        {courses.length} 件中 {startIndex + 1}-{Math.min(endIndex, courses.length)} 件を表示
      </Typography>
    </Box>
  );
}

/**
 * メインアプリケーションコンポーネント
 */
function App() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [token, setToken] = useState("");
  const [courses, setCourses] = useState<any[]>([]);
  const [progress, setProgress] = useState<any>([]); // 進捗は配列で初期化
  const [showProfile, setShowProfile] = useState(false);
  const [snackbar, setSnackbar] = useState<{open: boolean, message: string, severity: "success"|"error"|"info"|"warning"}>({open: false, message: "", severity: "info"});
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [users, setUsers] = useState<any[]>([]); // 全ユーザー情報

  // 初回マウント時にlocalStorageから認証情報を復元
  useEffect(() => {
    const savedToken = localStorage.getItem("token");
    const savedUsername = localStorage.getItem("username");
    if (savedToken && savedUsername) {
      setToken(savedToken);
      setUsername(savedUsername);
      setIsLoggedIn(true);
    }
  }, []);

  /**
   * 全ユーザー情報を取得する関数
   */
  const fetchAllUsers = async () => {
    try {
      const usersRes = await axios.get(`${API_URL}/admin/users`);
      setUsers(usersRes.data);
    } catch (error) {
      console.error("ユーザー一覧取得失敗:", error);
      setSnackbar({open: true, message: "ユーザー一覧取得失敗", severity: "error"});
    }
  };

  /**
   * コース一覧を取得する関数
   */
  const fetchCourses = async () => {
    try {
      const res = await axios.get(`${API_URL}/courses`);
      setCourses(res.data);
    } catch (error) {
      console.error("コース取得失敗:", error);
      setSnackbar({open: true, message: "コース取得失敗", severity: "error"});
    }
  };

  /**
   * 現在のユーザーの進捗を取得する関数
   */
  const fetchProgress = async () => {
    // トークンとユーザー名がなければ処理しない
    if (!token || !username) return;
    try {
      const res = await axios.get(`${API_URL}/progress/${username}`);
      setProgress(res.data);
      // 自分の進捗表示時もユーザー情報を取得しておく
      await fetchAllUsers();
    } catch (error) {
      console.error("ユーザー進捗取得失敗:", error);
      setSnackbar({open: true, message: "進捗取得失敗", severity: "error"});
    }
  };

  /**
   * 全ユーザーの進捗を取得する関数
   */
  const fetchAllProgress = async () => {
    // トークンがなければ処理しない
    if (!token) return;
    try {
      const res = await axios.get(`${API_URL}/progress`);
      setProgress(res.data);
      // 全ユーザー進捗表示時は、最新のユーザーリストも取得しておく
      await fetchAllUsers();
    } catch (error) {
      console.error("全ユーザー進捗取得失敗:", error);
      setSnackbar({open: true, message: "全ユーザー進捗取得失敗", severity: "error"});
    }
  };

  /**
   * ログイン処理
   */
  const login = async () => {
    try {
      const res = await axios.post(`${API_URL}/login`, { username, password });
      setToken(res.data.access_token);
      setSnackbar({open: true, message: "ログイン成功", severity: "success"});
      setIsLoggedIn(true);
      // localStorageに保存
      localStorage.setItem("token", res.data.access_token);
      localStorage.setItem("username", username);
      // ここではデータフェッチは行わず、useEffectに任せる
    } catch (error) {
      console.error("ログイン失敗:", error);
      setSnackbar({open: true, message: "ログイン失敗", severity: "error"});
    }
  };

  /**
   * コース参加処理
   * @param {number} courseId - 参加するコースのID
   */
  const joinCourse = async (courseId: number) => {
    if (!username) {
      setSnackbar({open: true, message: "ユーザー名を入力してください", severity: "warning"});
      return;
    }
    try {
      await axios.post(`${API_URL}/courses/${courseId}/join`, { username });
      setSnackbar({open: true, message: "コース参加申請しました", severity: "success"});
      // 参加後、進捗を再フェッチして更新
      await fetchProgress();
    } catch (error) {
      console.error("参加申請失敗:", error);
      setSnackbar({open: true, message: "参加申請失敗", severity: "error"});
    }
  };

  // ログイン成功時に初期データをフェッチするためのuseEffect
  useEffect(() => {
    if (isLoggedIn && token) {
      const loadInitialData = async () => {
        // コース、ユーザー、進捗の順にフェッチすることで、依存関係を解決
        await fetchCourses();
        await fetchAllUsers();
        await fetchProgress(); // ログインユーザーの進捗を最初に表示
      };
      loadInitialData();
    }
  }, [isLoggedIn, token, username]); // isLoggedIn, token, usernameが変更されたときに実行

  // プロフィールページ表示中はプロフィールコンポーネントをレンダリング
  if (showProfile) {
    return <ProfilePage username={username} onBack={() => setShowProfile(false)} />;
  }

  // 未ログイン時の表示
  if (!isLoggedIn) {
    return (
      <Box sx={{ bgcolor: "#f5f7fa", minHeight: "100vh", display: 'flex', flexDirection: 'column' }}>
        <AppBar position="static" color="primary">
          <Toolbar>
            <SchoolIcon sx={{ mr: 2 }} />
            <Typography variant="h6" sx={{ flexGrow: 1 }}>
              無敗塾 オンライン学習サービス
            </Typography>
          </Toolbar>
        </AppBar>
        <Container maxWidth="sm" sx={{ mt: 8, flexGrow: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Paper sx={{ p: 4, borderRadius: 2, boxShadow: 3, width: '100%' }} elevation={3}>
            <Typography variant="h5" gutterBottom align="center">ログイン</Typography>
            <Box display="flex" flexDirection="column" gap={2} alignItems="center">
              <TextField label="ユーザー名" value={username} onChange={e => setUsername(e.target.value)} size="small" fullWidth sx={{ borderRadius: 1 }} />
              <TextField label="パスワード" type="password" value={password} onChange={e => setPassword(e.target.value)} size="small" fullWidth sx={{ borderRadius: 1 }} />
              <Button variant="contained" color="primary" onClick={login} fullWidth sx={{ borderRadius: 1 }}>ログイン</Button>
            </Box>
          </Paper>
        </Container>
        <Snackbar open={snackbar.open} autoHideDuration={3000} onClose={() => setSnackbar({...snackbar, open: false})}>
          <Alert severity={snackbar.severity} sx={{ width: '100%' }}>{snackbar.message}</Alert>
        </Snackbar>
      </Box>
    );
  }

  // ログイン後のメインアプリケーション表示
  return (
    <Box sx={{ bgcolor: "#f5f7fa", minHeight: "100vh", display: 'flex', flexDirection: 'column' }}>
      <AppBar position="static" color="primary">
        <Toolbar>
          <SchoolIcon sx={{ mr: 2 }} />
          <Typography variant="h6" sx={{ flexGrow: 1 }}>
            無敗塾 オンライン学習サービス
          </Typography>
          <Button color="inherit" onClick={() => setShowProfile(true)} startIcon={<PersonIcon />}>プロフィール</Button>
          {isLoggedIn && (
            <Button
              color="inherit"
              onClick={() => {
                setIsLoggedIn(false);
                setToken("");
                setUsername("");
                setPassword("");
                setCourses([]);
                setProgress([]); // 配列としてクリア
                setUsers([]);
                // localStorageから削除
                localStorage.removeItem("token");
                localStorage.removeItem("username");
              }}
            >
              ログアウト
            </Button>
          )}
        </Toolbar>
      </AppBar>
      <Container maxWidth="md" sx={{ mt: 4, flexGrow: 1 }}>
        <Paper sx={{ p: 3, mb: 4, borderRadius: 2, boxShadow: 3 }} elevation={3}>
          <Typography variant="h5" gutterBottom>コース一覧</Typography>
          <Button variant="outlined" onClick={fetchCourses} sx={{ mb: 2, borderRadius: 1 }}>コース再取得</Button>
          <CourseCards courses={courses} onJoin={joinCourse} username={username} />
        </Paper>
        <Paper sx={{ p: 3, mb: 4, borderRadius: 2, boxShadow: 3 }} elevation={3}>
          <Typography variant="h5" gutterBottom>進捗管理</Typography>
          <Box display="flex" gap={2} mb={2}>
            <Button variant="outlined" onClick={fetchProgress} sx={{ borderRadius: 1 }}>自分のみ</Button>
            <Button variant="outlined" onClick={fetchAllProgress} sx={{ borderRadius: 1 }}>全ユーザー</Button>
          </Box>
          <ProgressCards progress={progress} courses={courses} users={users} />
        </Paper>
      </Container>
      <Snackbar open={snackbar.open} autoHideDuration={3000} onClose={() => setSnackbar({...snackbar, open: false})}>
        <Alert severity={snackbar.severity} sx={{ width: '100%' }}>{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}

export default App;