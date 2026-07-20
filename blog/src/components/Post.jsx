import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { getPost } from '../posts.js';
import CodeBlock from './CodeBlock.jsx';

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
        <div className="post-card-art">
          {post.image && <img className="post-card-still" src={post.image} alt="" />}
          {post.gif && <img className="post-card-gif" src={post.gif} alt="" />}
        </div>
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
      <div className="post-body">
        <ReactMarkdown remarkPlugins={[remarkGfm]} components={{ code: CodeBlock }}>
          {post.content}
        </ReactMarkdown>
      </div>
      <p>
        <Link to="/">← all posts</Link>
      </p>
    </article>
  );
}
