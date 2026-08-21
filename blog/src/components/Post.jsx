import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { getPost } from '../posts.js';
import CardArt from './CardArt.jsx';

export default function Post() {
  const { slug } = useParams();
  const post = getPost(slug);
  const [hovered, setHovered] = useState(false);

  if (!post) {
    return (
      <>
        <h1>Not found</h1>
        <p>
          No post here. <Link to="/">Back to all posts</Link>
        </p>
      </>
    );
  }

  return (
    <article>
      <header
        className={`post-hero${hovered ? ' is-hovered' : ''}`}
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
      >
        <CardArt image={post.image} gif={post.gif} active={hovered} />
        <div className="post-hero-text">
          <h1>{post.title}</h1>
          {post.date && (
            <time className="post-meta" dateTime={post.date}>
              {post.date}
            </time>
          )}
          {post.description && <p className="post-description">{post.description}</p>}
        </div>
      </header>
      <div className="post-body" dangerouslySetInnerHTML={{ __html: post.content }} />
      <p>
        <Link to="/">← all posts</Link>
      </p>
    </article>
  );
}
