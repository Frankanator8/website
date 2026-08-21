import { useState } from 'react';
import { Link } from 'react-router-dom';
import CardArt from './CardArt.jsx';

export default function PostCard({ post }) {
  const [hovered, setHovered] = useState(false);

  return (
    <Link
      to={`/post/${post.slug}`}
      className={`post-card${hovered ? ' is-hovered' : ''}`}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      onFocus={() => setHovered(true)}
      onBlur={() => setHovered(false)}
    >
      <CardArt image={post.image} gif={post.gif} active={hovered} />
      <div className="post-card-text">
        <h2>{post.title}</h2>
        {post.date && (
          <time className="post-meta" dateTime={post.date}>
            {post.date}
          </time>
        )}
        {post.description && <p>{post.description}</p>}
      </div>
    </Link>
  );
}
