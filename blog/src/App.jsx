import { Routes, Route } from 'react-router-dom';
import Layout from './components/Layout.jsx';
import PostList from './components/PostList.jsx';
import Post from './components/Post.jsx';

export default function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path="/" element={<PostList />} />
        <Route path="/post/:slug" element={<Post />} />
      </Route>
    </Routes>
  );
}
