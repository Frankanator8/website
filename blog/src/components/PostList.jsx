import { posts } from '../posts.js';
import PostCard from './PostCard.jsx';

export default function PostList() {
  return (
    <div className="post-grid">
      {posts.map((post) => (
        <PostCard key={post.slug} post={post} />
      ))}
    </div>
  );
}
