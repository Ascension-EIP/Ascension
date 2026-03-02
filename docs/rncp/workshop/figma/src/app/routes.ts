import { createBrowserRouter } from "react-router";
import { Layout } from "./components/Layout";
import Home from "./pages/Home";
import Upload from "./pages/Upload";
import Stats from "./pages/Stats";
import Profile from "./pages/Profile";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: Layout,
    children: [
      { index: true, Component: Home },
      { path: "upload", Component: Upload },
      { path: "stats", Component: Stats },
      { path: "profile", Component: Profile },
    ],
  },
]);
