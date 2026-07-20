import { useState } from 'react';
import { Link } from 'react-router-dom';

export default function PostCard({ post }) {
  // The gif is only fetched once the card has been hovered, then kept mounted
  // so later hovers cross-fade instantly.
  const [gifLoaded, setGifLoaded] = useState(false);
  const [hovered, setHovered] = useState(false);

  const activate = () => {
    setHovered(true);
    setGifLoaded(true);
  };

  return (
    <Link
      to={`/post/${post.slug}`}
      className={`post-card${hovered ? ' is-hovered' : ''}`}
      onMouseEnter={activate}
      onMouseLeave={() => setHovered(false)}
      onFocus={activate}
      onBlur={() => setHovered(false)}
    >
      <div className="post-card-art">
        {post.image && <img className="post-card-still" src={post.image} alt="" />}
        {post.gif && gifLoaded && (
          <img className="post-card-gif" src={post.gif} alt="" />
        )}
      </div>
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
