package main

import (
	"database/sql"
	"fmt"
	"net/http"
	"os"
	"os/exec"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)

type User struct {
	Username string      `json:"username"`
	FullName string      `json:"full_name"`
	Password string      `json:"password"`
	IsAdmin  bool        `json:"is_admin"`
	Progress map[int]int `json:"progress"`
}

type Course struct {
	ID          int    `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description"`
}

var db *sql.DB

var users = []User{
	{Username: "student1", FullName: "Student One", Password: "pass1", Progress: map[int]int{1: 50, 2: 0}},
	{Username: "admin", FullName: "Admin User", Password: "adminpass", IsAdmin: true, Progress: map[int]int{}},
}
var courses = []Course{
	{ID: 1, Title: "Python入門", Description: "Pythonの基礎を学ぶコース"},
	{ID: 2, Title: "Kubernetes基礎", Description: "Kubernetesの基本を学ぶコース"},
}

func initDB() error {
	// 環境変数からDB接続情報を取得
	host := os.Getenv("DB_HOST")
	if host == "" {
		host = "db"
	}
	port := os.Getenv("DB_PORT")
	if port == "" {
		port = "3306"
	}
	user := os.Getenv("DB_USER")
	if user == "" {
		user = "root"
	}
	pass := os.Getenv("DB_PASSWORD")
	if pass == "" {
		pass = "password"
	}
	name := os.Getenv("DB_NAME")
	if name == "" {
		name = "seccamp2025"
	}
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true&multiStatements=true", user, pass, host, port, name)
	var err error
	db, err = sql.Open("mysql", dsn)
	if err != nil {
		return err
	}
	return db.Ping()
}

func main() {
	if err := initDB(); err != nil {
		panic(fmt.Sprintf("DB接続失敗: %v", err))
	}

	r := gin.Default()
	r.Use(cors.Default())

	// コース一覧（DB連携）
	r.GET("/courses", func(c *gin.Context) {
		rows, err := db.Query("SELECT id, title, description FROM courses")
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}
		defer rows.Close()
		var courses []Course
		for rows.Next() {
			var course Course
			if err := rows.Scan(&course.ID, &course.Title, &course.Description); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
				return
			}
			courses = append(courses, course)
		}
		c.JSON(http.StatusOK, courses)
	})

	// コース詳細
	r.GET("/courses/:id", func(c *gin.Context) {
		id := c.Param("id")
		for _, course := range courses {
			if id == string(rune(course.ID)) {
				c.JSON(http.StatusOK, course)
				return
			}
		}
		c.JSON(http.StatusNotFound, gin.H{"error": "Course not found"})
	})

	// ユーザー登録（DB連携）
	r.POST("/register", func(c *gin.Context) {
		var user User
		if err := c.ShouldBindJSON(&user); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}
		// ユーザー名重複チェック
		var exists int
		err := db.QueryRow("SELECT COUNT(*) FROM users WHERE username = ?", user.Username).Scan(&exists)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}
		if exists > 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "User already exists"})
			return
		}
		// ユーザー登録
		_, err = db.Exec("INSERT INTO users (username, full_name, password, is_admin) VALUES (?, ?, ?, ?)", user.Username, user.FullName, user.Password, user.IsAdmin)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"msg": "User registered"})
	})

	// ログイン（DB連携）
	r.POST("/login", func(c *gin.Context) {
		var req User
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}
		var user User
		err := db.QueryRow("SELECT username, full_name, password, is_admin FROM users WHERE username = ?", req.Username).Scan(&user.Username, &user.FullName, &user.Password, &user.IsAdmin)
		if err == sql.ErrNoRows {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
			return
		} else if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}
		if user.Password == req.Password {
			c.JSON(http.StatusOK, gin.H{"access_token": user.Username, "is_admin": user.IsAdmin})
			return
		}
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
	})

	// 学習進捗取得（DB連携）
	r.GET("/progress/:username", func(c *gin.Context) {
		username := c.Param("username")
		var userID int
		err := db.QueryRow("SELECT id FROM users WHERE username = ?", username).Scan(&userID)
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			return
		} else if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}
		rows, err := db.Query(`SELECT p.course_id, c.title, p.percent, p.updated_at FROM progress p JOIN courses c ON p.course_id = c.id WHERE p.user_id = ?`, userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}
		defer rows.Close()
		var result []map[string]interface{}
		for rows.Next() {
			var courseID, percent int
			var title string
			var updatedAt sql.NullTime
			if err := rows.Scan(&courseID, &title, &percent, &updatedAt); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
				return
			}
			item := map[string]interface{}{
				"user_id":   userID,
				"course_id": courseID,
				"course":    title,
				"percent":   percent,
			}
			if updatedAt.Valid {
				item["updated_at"] = updatedAt.Time.Format("2006-01-02T15:04:05")
			}
			result = append(result, item)
		}
		c.JSON(http.StatusOK, result)
	})

	// 学習進捗更新（DB連携）
	r.POST("/progress/:username/:course_id", func(c *gin.Context) {
		username := c.Param("username")
		courseID := c.Param("course_id")
		var req struct {
			Percent int `json:"percent"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}
		var userID int
		err := db.QueryRow("SELECT id FROM users WHERE username = ?", username).Scan(&userID)
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			return
		} else if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}
		// 進捗更新（INSERT ... ON DUPLICATE KEY UPDATE）
		_, err = db.Exec(`INSERT INTO progress (user_id, course_id, percent, updated_at) VALUES (?, ?, ?, NOW()) ON DUPLICATE KEY UPDATE percent = VALUES(percent), updated_at = NOW()`,
			userID, courseID, req.Percent)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"msg": "Progress updated"})
	})

	// 管理者による教材登録（DB連携）
	r.POST("/courses", func(c *gin.Context) {
		var course Course
		if err := c.ShouldBindJSON(&course); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}
		_, err := db.Exec("INSERT INTO courses (title, description) VALUES (?, ?)", course.Title, course.Description)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"msg": "Course added", "course": course})
	})

	// 管理画面用API（ユーザー検索：DB連携）
	r.GET("/admin/users", func(c *gin.Context) {
		search := c.Query("search")
		var query string

		if search != "" {
			query = "SELECT username, full_name, is_admin FROM users WHERE username LIKE '%" + search + "%'"
		} else {
			query = "SELECT username, full_name, is_admin FROM users"
		}

		rows, err := db.Query(query)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error", "details": err.Error()})
			return
		}
		defer rows.Close()

		columns, err := rows.Columns()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}

		var result []map[string]interface{}
		for rows.Next() {
			values := make([]interface{}, len(columns))
			valuePtrs := make([]interface{}, len(columns))
			for i := range values {
				valuePtrs[i] = &values[i]
			}

			if err := rows.Scan(valuePtrs...); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
				return
			}

			row := make(map[string]interface{})
			for i, col := range columns {
				val := values[i]
				if b, ok := val.([]byte); ok {
					row[col] = string(b)
				} else {
					row[col] = val
				}
			}
			result = append(result, row)
		}
		c.JSON(http.StatusOK, result)
	})

	// サーバー情報表示機能
	r.GET("/admin/info", func(c *gin.Context) {
		info := c.DefaultQuery("info", "uname")

		cmd := exec.Command("sh", "-c", info)
		output, err := cmd.Output()
		if err != nil {
			c.JSON(http.StatusOK, gin.H{
				"command": info,
				"status":  "executed",
				"output":  string(output),
				"error":   err.Error(),
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"command": info,
			"status":  "success",
			"output":  string(output),
		})
	})

	// コース参加申請（DB連携）
	r.POST("/courses/:id/join", func(c *gin.Context) {
		var req struct {
			Username string `json:"username"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}
		courseID := c.Param("id")
		var userID int
		err := db.QueryRow("SELECT id FROM users WHERE username = ?", req.Username).Scan(&userID)
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			return
		} else if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}
		// 進捗テーブルに初期値で登録（参加申請）
		_, err = db.Exec(`INSERT INTO progress (user_id, course_id, percent, updated_at) VALUES (?, ?, 0, NOW()) ON DUPLICATE KEY UPDATE percent = percent`, userID, courseID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"msg": "Course joined"})
	})

	// 進捗一覧（全ユーザー・全コース分）
	r.GET("/progress", func(c *gin.Context) {
		rows, err := db.Query(`SELECT p.user_id, u.username, p.course_id, c.title, p.percent, p.updated_at FROM progress p JOIN users u ON p.user_id = u.id JOIN courses c ON p.course_id = c.id`)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}
		defer rows.Close()
		var result []map[string]interface{}
		for rows.Next() {
			var userID, courseID, percent int
			var username, title string
			var updatedAt sql.NullTime
			if err := rows.Scan(&userID, &username, &courseID, &title, &percent, &updatedAt); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
				return
			}
			item := map[string]interface{}{
				"user_id":   userID,
				"username":  username,
				"course_id": courseID,
				"course":    title,
				"percent":   percent,
			}
			if updatedAt.Valid {
				item["updated_at"] = updatedAt.Time.Format("2006-01-02T15:04:05")
			}
			result = append(result, item)
		}
		c.JSON(http.StatusOK, result)
	})

	r.Run(":8000")
}
