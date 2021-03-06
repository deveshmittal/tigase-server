--
-- Tigase XMPP Server - The instant messaging server
-- Copyright (C) 2004 Tigase, Inc. (office@tigase.com)
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as published by
-- the Free Software Foundation, version 3 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program. Look for COPYING file in the top folder.
-- If not, see http://www.gnu.org/licenses/.
--

-- QUERY START:
create table if not exists tig_users (
	uid bigserial,

	-- Jabber User ID
	user_id varchar(2049) NOT NULL,
	-- User password encrypted or not
	user_pw varchar(255) default NULL,
	-- Time the account has been created
	acc_create_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
	-- Time of the last user login
	last_login timestamp with time zone,
	-- Time of the last user logout
	last_logout timestamp with time zone,
	-- User online status, if > 0 then user is online, the value
	-- indicates the number of user connections.
	-- It is incremented on each user login and decremented on each
	-- user logout.
	online_status int default 0,
	-- Number of failed login attempts
	failed_logins int default 0,
	-- User status, whether the account is active or disabled
	-- >0 - account active, 0 - account disabled
	account_status int default 1,

	primary key (uid)
);
-- QUERY END:
-- QUERY START:
do $$
begin
    if to_regclass('public.user_id') is null then
        create unique index user_id on tig_users ( lower(user_id) );
    end if;
end$$;
-- QUERY END:
-- QUERY START:
do $$
begin
    if to_regclass('public.user_pw') is null then
        create index user_pw on tig_users (user_pw);
    end if;
end$$;
-- QUERY END:
-- QUERY START:
do $$
begin
    if to_regclass('public.last_login') is null then
        create index last_login on tig_users (last_login);
    end if;
end$$;
-- QUERY END:
-- QUERY START:
do $$
begin
    if to_regclass('public.last_logout') is null then
        create index last_logout on tig_users (last_logout);
    end if;
end$$;
-- QUERY END:
-- QUERY START:
do $$
begin
    if to_regclass('public.account_status') is null then
        create index account_status on tig_users (account_status);
    end if;
end$$;
-- QUERY END:
-- QUERY START:
do $$
begin
    if to_regclass('public.online_status') is null then
        create index online_status on tig_users (online_status);
    end if;
end$$;
-- QUERY END:

-- QUERY START:
create table if not exists tig_nodes (
       nid bigserial,
       parent_nid bigint,
       uid bigint NOT NULL references tig_users(uid),

       node varchar(255) NOT NULL,

       primary key (nid)
);
-- QUERY END:
-- QUERY START:
do $$
begin
    if to_regclass('public.tnode') is null then
        create unique index tnode on tig_nodes ( parent_nid, uid, node );
    end if;
end$$;
-- QUERY END:
-- QUERY START:
do $$
begin
    if to_regclass('public.node') is null then
        create index node on tig_nodes ( node );
    end if;
end$$;
-- QUERY END:
-- QUERY START:
do $$
begin
    if to_regclass('public.nuid') is null then
        create index nuid on tig_nodes (uid);
    end if;
end$$;
-- QUERY END:
-- QUERY START:
do $$
begin
    if to_regclass('public.parent_nid') is null then
        create index parent_nid on tig_nodes (parent_nid);
    end if;
end$$;
-- QUERY END:

-- QUERY START:
create table if not exists tig_pairs (
       pid BIGSERIAL PRIMARY KEY,
       nid bigint references tig_nodes(nid),
       uid bigint NOT NULL references tig_users(uid),

       pkey varchar(255) NOT NULL,
       pval text
);
-- QUERY END:
-- QUERY START:
do $$
begin
    if to_regclass('public.pkey') is null then
        create index pkey on tig_pairs ( pkey );
    end if;
end$$;
-- QUERY END:
-- QUERY START:
do $$
begin
    if to_regclass('public.puid') is null then
        create index puid on tig_pairs (uid);
    end if;
end$$;
-- QUERY END:
-- QUERY START:
do $$
begin
    if to_regclass('public.pnid') is null then
        create index pnid on tig_pairs (nid);
    end if;
end$$;
-- QUERY END:

-- QUERY START:
create table if not exists tig_offline_messages (
    msg_id bigserial,
    ts timestamp with time zone default now(),
    expired timestamp with time zone,
    sender varchar(2049),
    receiver varchar(2049) not null,
    msg_type int not null default 0,
    message text not null,

    primary key(msg_id)
);
-- QUERY END:

-- QUERY START:
create table if not exists tig_broadcast_messages (
    id varchar(128) not null,
    expired timestamp with time zone not null,
    msg text not null,
    primary key (id)
);
-- QUERY END:

-- QUERY START:
create table if not exists tig_broadcast_jids (
    jid_id bigserial,
    jid varchar(2049) not null,

    primary key (jid_id)
);
-- QUERY END:
-- QUERY START:
do $$
begin
    if to_regclass('public.tig_broadcast_jids_jid') is null then
        create index tig_broadcast_jids_jid on tig_broadcast_jids (lower(jid));
    end if;
end$$;
-- QUERY END:

-- QUERY START:
create table if not exists tig_broadcast_recipients (
    msg_id varchar(128) not null references tig_broadcast_messages(id),
    jid_id bigint not null references tig_broadcast_jids(jid_id),
    primary key (msg_id, jid_id)
);
-- QUERY END:

-- QUERY START:
do $$
begin
    if to_regclass('public.tig_offline_messages_expired') is null then
        create index tig_offline_messages_expired on tig_offline_messages (expired);
    end if;
    if to_regclass('public.tig_offline_messages_receiver') is null then
        create index tig_offline_messages_receiver on tig_offline_messages (lower(receiver));
    end if;
    if to_regclass('public.tig_offline_messages_receiver_sender') is null then
        create index tig_offline_messages_receiver_sender on tig_offline_messages (lower(receiver), lower(sender));
    end if;
end$$;
-- QUERY END:

-- QUERY START:
create table if not exists tig_cluster_nodes (
    hostname varchar(512) not null,
	secondary varchar(512),
    password varchar(255) not null,
    last_update timestamp with time zone default current_timestamp,
    port int,
    cpu_usage double precision not null,
    mem_usage double precision not null,
    primary key (hostname)
);
-- QUERY END:

-- ------------- Credentials support
-- QUERY START:
create table if not exists tig_user_credentials (
    uid bigint not null references tig_users(uid),
    username varchar(2049) not null,
    mechanism varchar(128) not null,
    value text not null,

    primary key (uid, username, mechanism)
);
-- QUERY END: