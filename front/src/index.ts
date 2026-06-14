import { Hono } from "hono";
import { homePage, privacyPage, supportPage } from "./site";

const app = new Hono();

app.get("/", (c) => c.html(homePage()));
app.get("/privacy", (c) => c.html(privacyPage()));
app.get("/support", (c) => c.html(supportPage()));

// 旧 GitHub Pages 形式（.html 付き）からの恒久リダイレクト。
app.get("/privacy.html", (c) => c.redirect("/privacy", 301));
app.get("/support.html", (c) => c.redirect("/support", 301));
app.get("/index.html", (c) => c.redirect("/", 301));

export default app;
